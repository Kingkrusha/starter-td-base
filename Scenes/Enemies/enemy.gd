extends Area2D

var speed : int
var health : int
var reward: int
var path_follow : PathFollow2D
var speed_mult: float = 1.0
var slow_duration: float = 1.0
var enemy_type: Data.Enemy
var wave_idx: int = 0
var max_health: int

var resistances: Dictionary = {}
var immunities: Array = []
var special_id: String = "none"
var special_params: Dictionary = {}

var shield_current: float = 0.0
var shield_max: float = 0.0
var last_hit_time: float = 0.0
var first_hit_triggered: bool = false
var invulnerable_until: float = 0.0
var special_elapsed_time: float = 0.0
var phantom_speed_mult: float = 1.0

var slow_mult: float = 1.0
var external_boost_mult: float = 1.0
var external_boost_until: float = 0.0

var protector_aura_radius: float = 120.0
var protector_aura_resistance_mult: float = 0.35
var protector_aura_types: Array = []
var protector_aura_active: bool = false
var protector_aura_ring: Line2D

var adaptive_immunity_locked: bool = false
var adaptive_immunity_type: String = ""

# Burn effect tracking
var burn_damage_per_tick: int = 0
var burn_duration: float = 0.0
var burn_tick_speed: float = 0.2
var burn_elapsed: float = 0.0
var burn_next_tick: float = 0.0
var burn_source_tower: Tower = null
var is_dying: bool = false

signal special_death_effect(effect_id: String, payload: Dictionary)

func setup(new_path_follow : PathFollow2D, enemy_type: Data.Enemy, wave_idx: int = 0):
	path_follow = new_path_follow
	self.enemy_type = enemy_type
	self.wave_idx = wave_idx
	var enemy_data = Data.ENEMY_DATA[enemy_type]
	speed = enemy_data['speed']
	health = Data.get_scaled_health(enemy_type, wave_idx)
	max_health = health
	$ProgressBar.max_value = max_health
	$ProgressBar.value = 0
	var spawn_cost: int = int(enemy_data.get("spawn_cost", 0))
	if bool(enemy_data.get("is_special", true)):
		reward = int(floor(float(spawn_cost) * 1.5))
	else:
		reward = spawn_cost
	$Sprite.texture = load(enemy_data['texture'])
	resistances = enemy_data.get("resistances", {})
	immunities = enemy_data.get("immunities", [])
	special_id = String(enemy_data.get("special_id", "none"))
	special_params = enemy_data.get("special_params", {})
	special_elapsed_time = 0.0
	last_hit_time = 0.0
	invulnerable_until = 0.0
	_initialize_special_state()
	
func _process(delta):
	special_elapsed_time += delta
	_process_special_state(delta)
	_process_burn_damage(delta)
	_update_external_speed_boost_state()
	_update_protector_aura_state()
	_update_speed_state()
	path_follow.progress += ((speed * delta) * speed_mult)
	$ProgressBar.rotation = -path_follow.rotation 
	$ProgressBar.position = Vector2(0,-12)
	if _is_temporarily_invulnerable():
		$Sprite.modulate = Color(1.0, 1.0, 1.0, 0.6)
	elif shield_current > 0:
		$Sprite.modulate = Color.YELLOW
	elif speed_mult > 1.0:
		$Sprite.modulate = Color(0.72, 0.5, 1.0, 1.0)
	elif speed_mult < 1.0:
		$Sprite.modulate = Color.CADET_BLUE
	else:
		$Sprite.modulate = Color.WHITE
	
	if path_follow.progress_ratio >= 0.995:
		Data.health -= health
		queue_free()


func _on_area_entered(bullet: Area2D):
	hit(bullet)
	if bullet.pierce > 0:
		bullet.pierce -= 1
	else: 
		bullet.queue_free.call_deferred()
		
func hit(ref):
	if is_dying:
		return
	if _is_temporarily_invulnerable():
		return
	flash()
	# Convert bullet object to Dictionary for damage computation
	var bullet_data: Dictionary = {
		"damage": ref.damage,
		"dmg_type": ref.dmg_type
	}
	var damage_to_apply := _compute_incoming_damage(bullet_data)
	health -= damage_to_apply
	$ProgressBar.value += damage_to_apply
	var source_tower: Tower = null
	if ref is Tower:
		source_tower = ref
	elif ref != null and "parent_tower" in ref and ref.parent_tower is Tower:
		source_tower = ref.parent_tower
	Data.record_damage_dealt(damage_to_apply, source_tower)
	_on_damage_taken(bullet_data, damage_to_apply)
	if ref.dmg_type == "slow":
		apply_slow(ref.parent_tower.slow, ref.parent_tower.slow_duration)
	elif ref.dmg_type == "burn":
		apply_burn(ref.burn_damage, ref.burn_duration, ref.burn_tick_speed, source_tower)
	#print("Dealing ", ref.damage, " damage")
	if health <=0 :
		is_dying = true
		_emit_special_death_effects()
		Data.record_enemy_defeated()
		Data.record_plant_money_generated(reward)
		GameFarmManager.money += reward
		#print_debug("Reward ", reward)
		queue_free.call_deferred()

func flash():
	var tween = create_tween()
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 1.0, 0.1)
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 0.0, 0.1)

func apply_slow( new_speed: float, duration: float ):
	if "slow" in immunities:
		return
	slow_mult = min(slow_mult, new_speed)
	$SlowTimer.wait_time = duration
	$SlowTimer.start()


func _on_slow_timer_timeout():
	slow_mult = 1.0


func apply_burn(damage_per_tick: int, duration: float, tick_speed: float, source_tower: Tower = null) -> void:
	burn_damage_per_tick = damage_per_tick
	burn_duration = duration
	burn_tick_speed = tick_speed
	burn_elapsed = 0.0
	burn_next_tick = 0.0
	burn_source_tower = source_tower


func _initialize_special_state() -> void:
	# Initialize cached runtime values for the selected special.
	match special_id:
		"shield_recharge":
			shield_max = float(special_params.get("shield_max", 0))
			shield_current = shield_max
		"phantom_phase":
			first_hit_triggered = false
			invulnerable_until = 0.0
			phantom_speed_mult = float(special_params.get("speed_mult", 1.0))
		"protector_aura":
			protector_aura_radius = float(special_params.get("aura_radius", 120.0))
			protector_aura_resistance_mult = float(special_params.get("aura_resistance_mult", 0.35))
			protector_aura_types = special_params.get("aura_types", ["slow", "fire", "explosion"])
			_create_protector_aura_visual()
		"adaptive_defense":
			adaptive_immunity_locked = false
			adaptive_immunity_type = ""
		_:
			pass


func _process_special_state(delta: float) -> void:
	# Tick per-frame special behavior.
	match special_id:
		"shield_recharge":
			var recharge_delay = float(special_params.get("recharge_delay", 0.0))
			var recharge_rate = float(special_params.get("recharge_rate", 0.0))
			# Only recharge if enough time has passed since last hit
			if special_elapsed_time - last_hit_time >= recharge_delay:
				shield_current += recharge_rate * delta
				shield_current = min(shield_current, shield_max)
		"phantom_phase":
			pass
		_:
			pass


func _compute_incoming_damage(ref: Dictionary) -> int:
	var incoming_damage: int = int(ref.get("damage", 0))
	var dmg_type = ref.get("dmg_type", "normal")
	
	# Check immunities first
	if dmg_type in immunities:
		return 0
	
	# Apply resistances
	if dmg_type in resistances:
		incoming_damage = int(float(incoming_damage) * resistances[dmg_type])

	# Protector aura: nearby protector grants non-stacking resistance to configured types.
	if protector_aura_active and dmg_type in protector_aura_types:
		incoming_damage = int(float(incoming_damage) * protector_aura_resistance_mult)
	
	# Apply flat reduction
	if special_id == "flat_damage_reduction":
		var reduce_by = int(special_params.get("reduce_by", 0))
		var min_damage = int(special_params.get("min_damage", 1))
		incoming_damage = max(min_damage, incoming_damage - reduce_by)
	
	# Apply shield absorption
	var shield_absorbed = mini(incoming_damage, int(shield_current))
	shield_current -= shield_absorbed
	incoming_damage -= shield_absorbed
	
	return max(0, incoming_damage)


func _on_damage_taken(_ref: Dictionary, _damage_amount: int) -> void:
	# Update special runtime state after a hit.
	last_hit_time = special_elapsed_time
	
	# Trigger first-hit invulnerability window
	if special_id == "phantom_phase" and not first_hit_triggered:
		first_hit_triggered = true
		var duration = float(special_params.get("invuln_duration", 1.0))
		invulnerable_until = special_elapsed_time + duration

	if special_id == "adaptive_defense" and not adaptive_immunity_locked:
		var dmg_type := String(_ref.get("dmg_type", "normal"))
		if dmg_type != "":
			adaptive_immunity_locked = true
			adaptive_immunity_type = dmg_type
			if adaptive_immunity_type not in immunities:
				immunities.append(adaptive_immunity_type)


func _is_temporarily_invulnerable() -> bool:
	return special_elapsed_time < invulnerable_until


func _update_speed_state() -> void:
	var phantom_mult := 1.0
	if special_id == "phantom_phase" and _is_temporarily_invulnerable():
		phantom_mult = max(1.0, phantom_speed_mult)

	var combined := slow_mult * phantom_mult * external_boost_mult
	if special_id == "booster_on_death":
		combined = max(1.0, combined)

	speed_mult = combined


func _update_external_speed_boost_state() -> void:
	if external_boost_until > 0.0 and special_elapsed_time >= external_boost_until:
		external_boost_until = 0.0
		external_boost_mult = 1.0


func apply_external_speed_boost(mult: float, duration: float) -> void:
	if mult <= 1.0 or duration <= 0.0:
		return
	# Non-stacking: ignore new boosts while one is active.
	if special_elapsed_time < external_boost_until:
		return
	external_boost_mult = mult
	external_boost_until = special_elapsed_time + duration


func _update_protector_aura_state() -> void:
	protector_aura_active = false
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self:
			continue
		if not (node is Area2D):
			continue
		if not node.has_method("_is_protector_enemy"):
			continue
		if not node._is_protector_enemy():
			continue
		var radius := float(node.get("protector_aura_radius"))
		if node.global_position.distance_to(global_position) <= radius:
			protector_aura_active = true
			break


func _is_protector_enemy() -> bool:
	return special_id == "protector_aura"


func _create_protector_aura_visual() -> void:
	if protector_aura_ring and is_instance_valid(protector_aura_ring):
		return

	var ring := Line2D.new()
	var points := PackedVector2Array()
	var segment_count := 48
	for i in range(segment_count):
		var angle := TAU * float(i) / float(segment_count)
		points.append(Vector2.RIGHT.rotated(angle) * protector_aura_radius)
	ring.points = points
	ring.closed = true
	ring.width = 1.4
	ring.default_color = Color(0.95, 0.85, 0.2, 0.65)
	ring.antialiased = true
	add_child(ring)
	protector_aura_ring = ring


func _process_burn_damage(delta: float) -> void:
	if burn_duration <= 0.0:
		return
	
	burn_elapsed += delta
	if burn_elapsed >= burn_duration:
		# Burn effect expired
		burn_duration = 0.0
		burn_elapsed = 0.0
		burn_next_tick = 0.0
		return
	
	# Check if it's time for the next tick
	if burn_elapsed >= burn_next_tick:
		health -= burn_damage_per_tick
		$ProgressBar.value += burn_damage_per_tick
		Data.record_damage_dealt(burn_damage_per_tick, burn_source_tower)
		burn_next_tick += burn_tick_speed
		
		# Check if enemy died from burn
		if health <= 0:
			if is_dying:
				return
			is_dying = true
			_emit_special_death_effects()
			Data.record_enemy_defeated()
			Data.record_plant_money_generated(reward)
			GameFarmManager.money += reward
			queue_free.call_deferred()


func _emit_special_death_effects() -> void:
	match special_id:
		"spawn_on_death":
			# Design lock: this special always splits into 3 basic enemies.
			var spawn_type = Data.Enemy.DEFAULT
			var spawn_count = 3
			var spawn_delay = float(special_params.get("spawn_delay", 0.08))
			special_death_effect.emit("spawn_on_death", {
				"origin": global_position,
				"path_progress": path_follow.progress if path_follow else 0.0,
				"wave_idx": wave_idx,
				"spawn_enemy_type": spawn_type,
				"spawn_count": spawn_count,
				"spawn_delay": spawn_delay
			})
		"death_disable_pulse":
			var pulse_radius = float(special_params.get("pulse_radius", 180.0))
			var disable_duration = float(special_params.get("disable_duration", 2.5))
			special_death_effect.emit("death_disable_pulse", {
				"origin": global_position,
				"pulse_radius": pulse_radius,
				"disable_duration": disable_duration
			})
		"booster_on_death":
			var boost_radius := float(special_params.get("boost_radius", 120.0))
			var boost_duration := float(special_params.get("boost_duration", 1.0))
			var boost_mult := float(special_params.get("boost_mult", 1.7))
			special_death_effect.emit("death_speed_boost", {
				"origin": global_position,
				"boost_radius": boost_radius,
				"boost_duration": boost_duration,
				"boost_mult": boost_mult
			})
		_:
			pass
