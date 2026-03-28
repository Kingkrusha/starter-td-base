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
var full_hp_speed_mult: float = 1.0

signal special_death_effect(effect_id: String, payload: Dictionary)

func setup(new_path_follow : PathFollow2D, enemy_type: Data.Enemy, wave_idx: int = 0):
	path_follow = new_path_follow
	self.enemy_type = enemy_type
	self.wave_idx = wave_idx
	var enemy_data = Data.ENEMY_DATA[enemy_type]
	speed = enemy_data['speed']
	health = Data.get_scaled_health(enemy_type, wave_idx)
	max_health = health
	reward = round(float(health)/2)
	$Sprite.texture = load(enemy_data['texture'])
	resistances = enemy_data.get("resistances", {})
	immunities = enemy_data.get("immunities", [])
	special_id = String(enemy_data.get("special_id", "none"))
	special_params = enemy_data.get("special_params", {})
	_initialize_special_state()
	
func _process(delta):
	_process_special_state(delta)
	path_follow.progress += ((speed * delta) * speed_mult)
	
	# Update sprite modulation based on special state
	if _is_temporarily_invulnerable():
		$Sprite.modulate = Color.YELLOW
	elif shield_current > 0:
		$Sprite.modulate = Color.LIGHT_BLUE
	elif speed_mult < 1.0:
		$Sprite.modulate = Color.CADET_BLUE
	else:
		$Sprite.modulate = Color.WHITE
	
	if path_follow.progress_ratio >= 0.999:
		Data.health -= health
		queue_free()


func _on_area_entered(bullet: Area2D):
	hit(bullet)
	if bullet.pierce > 0:
		bullet.pierce -= 1
	else: 
		bullet.queue_free.call_deferred()
		
func hit(ref):
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
	_on_damage_taken(bullet_data, damage_to_apply)
	if ref.dmg_type == "slow":
		apply_slow(ref.parent_tower.slow, ref.parent_tower.slow_duration)
	#print("Dealing ", ref.damage, " damage")
	if health <=0 :
		_emit_special_death_effects()
		
		GameFarmManager.money += reward
		#print_debug("Reward ", reward)
		queue_free.call_deferred()

func flash():
	var tween = create_tween()
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 1.0, 0.1)
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 0.0, 0.1)

func apply_slow( new_speed: float, duration: float ):
	speed_mult = min(speed_mult, new_speed)
	$SlowTimer.wait_time = duration
	$SlowTimer.start()


func _on_slow_timer_timeout():
	speed_mult = 1.0


func _initialize_special_state() -> void:
	# Initialize cached runtime values for the selected special.
	match special_id:
		"shield_recharge":
			shield_max = float(special_params.get("shield_max", 0))
			shield_current = shield_max
		"full_health_speed_boost":
			full_hp_speed_mult = float(special_params.get("speed_mult_at_full_hp", 1.0))
		"first_hit_invuln":
			first_hit_triggered = false
			invulnerable_until = 0.0
		_:
			pass


func _process_special_state(delta: float) -> void:
	# Tick per-frame special behavior.
	match special_id:
		"shield_recharge":
			var recharge_delay = float(special_params.get("recharge_delay", 0.0))
			var recharge_rate = float(special_params.get("recharge_rate", 0.0))
			var current_time = Time.get_ticks_msec() / 1000.0
			# Only recharge if enough time has passed since last hit
			if current_time - last_hit_time >= recharge_delay:
				shield_current += recharge_rate * delta
				shield_current = min(shield_current, shield_max)
		"full_health_speed_boost":
			# Apply speed boost only at full health
			if health >= max_health:
				speed_mult = full_hp_speed_mult
			else:
				speed_mult = 1.0
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
	last_hit_time = Time.get_ticks_msec() / 1000.0
	
	# Trigger first-hit invulnerability window
	if special_id == "first_hit_invuln" and not first_hit_triggered:
		first_hit_triggered = true
		var duration = float(special_params.get("invuln_duration", 1.0))
		invulnerable_until = Time.get_ticks_msec() / 1000.0 + duration


func _is_temporarily_invulnerable() -> bool:
	return Time.get_ticks_msec() / 1000.0 < invulnerable_until


func _emit_special_death_effects() -> void:
	# TODO: Emit special_death_effect with payloads for level-side handling.
	# Example effects: spawn_on_death, death_disable_pulse.
	pass
