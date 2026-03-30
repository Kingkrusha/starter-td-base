extends Node2D

var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
var bullet_scene = preload("res://scenes/bullets/bullet.tscn")
var explosion_scene = preload("res://scenes/bullets/explosion.tscn")
var bomb_scene = preload("res://scenes/bullets/bomb.tscn")
var tower_scenes = {
	Data.Tower.BASIC: "res://scenes/towers/tower_basic.tscn",
	Data.Tower.BLAST: "res://scenes/towers/tower_blaster.tscn",
	Data.Tower.MORTAR: "res://scenes/towers/tower_mortar.tscn",
	Data.Tower.SLOW: "res://scenes/towers/tower_slow.tscn",
	Data.Tower.BOMB: "res://scenes/towers/tower_bomb.tscn"}
	
var place_tower: bool:
	set(value):
		place_tower = value
		$BG/TowerPreview.visible = value
var selected_tower: Data.Tower
var current_tower: Tower
var tower_menu: bool
#var used_cells: Array[Vector2i]
var ongoing_wave: bool
var spawning_enemies: bool
var valid_placement: bool = true
var unlocked_special_pool: Array[Data.Enemy] = []
var pending_special_unlocks: Array[Dictionary] = []
var selected_specials: Array[Data.Enemy] = []
var last_special_pick_wave: int = -1
var DEBUG_ACTIVE: bool = true
const DEBUG_SPECIAL_SCHEDULER: bool = true
const DEBUG_ENEMY_HOTKEY_MAP := {
	KEY_QUOTELEFT: Data.Enemy.DEFAULT,
	KEY_1: Data.Enemy.FAST,
	KEY_2: Data.Enemy.STRONG,
	KEY_3: Data.Enemy.BIG,
	KEY_4: Data.Enemy.SPECIAL_BEHEMOTH,
	KEY_5: Data.Enemy.SPECIAL_SHIELD,
	KEY_6: Data.Enemy.SPECIAL_PHANTOM,
	KEY_7: Data.Enemy.SPECIAL_PROTECTOR,
	KEY_8: Data.Enemy.SPECIAL_DEATH_SPAWN,
	KEY_9: Data.Enemy.SPECIAL_FLAT_REDUCTION,
	KEY_0: Data.Enemy.SPECIAL_DEATH_DISABLE,
	KEY_Q: Data.Enemy.SPECIAL_ADAPTIVE_DEFENSE,
	KEY_W: Data.Enemy.SPECIAL_BOOSTER,
}
signal enable_wave_button()
signal special_enemy_approaching(enemy_type: Data.Enemy, unlock_wave: int)

func _ready() -> void:
	RenderingServer.set_default_clear_color('#e0f6f4')
	$UI.connect("start_wave", spawn_wave)
	special_enemy_approaching.connect(_on_special_enemy_approaching)
	_print_debug_bindings()
	#$"Player Camera".limit_bottom = $Background/WorldBounds/Bottom.global_position.y
	#$"Player Camera".limit_top = $Background/WorldBounds/Top.global_position.y
	#$"Player Camera".limit_left = $Background/WorldBounds/Left.global_position.x
	#$"Player Camera".limit_right = $Background/WorldBounds/Right.global_position.x


func _print_debug_bindings() -> void:
	if not DEBUG_ACTIVE:
		return

	print("[DEBUG] Debug features enabled")
	var debug_sections := [
		{
			"title": "Enemy spawn keys",
			"bindings": DEBUG_ENEMY_HOTKEY_MAP,
			"formatter": func(keycode: int, value: Variant) -> String: return "%s -> %s" % [OS.get_keycode_string(keycode), _enemy_debug_name(value)]
		},
		{
			"title": "Wave controls",
			"bindings": {
				KEY_EQUAL: "Increase wave",
				KEY_MINUS: "Decrease wave",
				KEY_KP_ADD: "Increase wave",
				KEY_KP_SUBTRACT: "Decrease wave"
			},
			"formatter": func(keycode: int, value: Variant) -> String: return "%s -> %s" % [OS.get_keycode_string(keycode), String(value)]
		}
	]

	for section in debug_sections:
		print("[DEBUG] %s:" % section["title"])
		var keys = section["bindings"].keys()
		keys.sort()
		for keycode in keys:
			print("  " + section["formatter"].call(keycode, section["bindings"][keycode]))


func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet, tower_ref: Node = null):
	if bullet_enum == Data.Bullet.SINGLE:
		var bullet = bullet_scene.instantiate()
		$Bullets.add_child(bullet)
		bullet.setup(pos, angle, bullet_enum, tower_ref)

	elif bullet_enum == Data.Bullet.FIRE:
		for enemy in get_tree().get_nodes_in_group('enemies'):
			if enemy in tower_ref.enemies:
				enemy.hit(tower_ref)
	elif bullet_enum == Data.Bullet.MORTAR_EXPLOSION:
		var explosion = explosion_scene.instantiate()
		explosion.setup(pos, tower_ref)
		$Bullets.add_child(explosion)
	elif bullet_enum == Data.Bullet.BOMB:
		var bomb = bomb_scene.instantiate()
		$Bullets.add_child(bomb)
		bomb.setup(pos, angle, bullet_enum, tower_ref)


func tower_selection(tower:Tower):
	if current_tower:
		current_tower.show_range = false
		current_tower.queue_redraw()
	current_tower = tower
	tower_menu = true
	$UI.show_tower_menu(tower)
	if tower.type == Data.Tower.MORTAR:
		tower.show_crosshair()



func _on_ui_place_tower(tower_type: Data.Tower):
	var placement_gate: Dictionary = Data.can_place_tower_from_plants(tower_type)
	if not bool(placement_gate.get("allowed", false)):
		print(String(placement_gate.get("reason", "Cannot place tower.")))
		return
	place_tower = true
	selected_tower = tower_type
	print('tower placement ', place_tower , tower_type)
	$BG/TowerPreview.texture = load(Data.TOWER_DATA[tower_type]['thumbnail'])
	if selected_tower == Data.Tower.MORTAR:
		return
	elif selected_tower == Data.Tower.BOMB:
		$BG/TowerPreview/RangePreview.range = Data.TOWER_DATA[selected_tower]['twr_range']
		$BG/TowerPreview/RangePreview.queue_redraw()
	else:
		$BG/TowerPreview/RangePreview.range = Data.UPGRADE_DATA[selected_tower]['tracks']['range']['base']
		$BG/TowerPreview/RangePreview.queue_redraw()
	
	
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_debug_key_input(event):
			return

	var raw_pos = get_local_mouse_position()
	#var pos = Vector2i(raw_pos.x / 16, raw_pos.y /16)
	var pos = Vector2i(raw_pos.x, raw_pos.y)
	$BG/TowerPreview.modulate = Color.RED if not valid_placement else Color.WHITE
	if event is InputEventMouseButton and event.button_mask == 1 and place_tower:
		#var tile_data =($BG/TileMapLayer.get_cell_tile_data(pos))
		if event.button_index == 1 and valid_placement == true: #and pos not in used_cells and tile_data is TileData and tile_data.get_custom_data("useable"):
			var placement_gate: Dictionary = Data.can_place_tower_from_plants(selected_tower)
			if not bool(placement_gate.get("allowed", false)):
				print(String(placement_gate.get("reason", "Cannot place tower.")))
				place_tower = false
				return
			#used_cells.append(pos)
			var tower = load(tower_scenes[selected_tower]).instantiate()
			tower.position = pos #*16 + Vector2i(8,8)
			tower.connect('shoot', create_bullet)
			tower.connect('select', tower_selection)
			$Towers.add_child(tower)
			place_tower = false
			Data.notify_tower_constraint_state_changed()
	
	if event is InputEventMouseButton and event.button_mask == 1 and current_tower:
		if current_tower.type == Data.Tower.MORTAR:
			current_tower.finish_placing()
			current_tower = null
	
	if event is InputEventMouseMotion and place_tower:
		var tower_pos = pos #*16 + Vector2i(8,8)
		$BG/TowerPreview.position = tower_pos
	
	if event is InputEventMouseMotion and tower_menu:
		if current_tower and current_tower.type == Data.Tower.MORTAR:
			current_tower.crosshair_pos_update(pos)
	if Input.is_action_just_pressed("exit"):
		place_tower = false


func _handle_debug_key_input(event: InputEventKey) -> bool:
	if not DEBUG_ACTIVE:
		return false

	if DEBUG_ENEMY_HOTKEY_MAP.has(event.keycode):
		var enemy_type: Data.Enemy = DEBUG_ENEMY_HOTKEY_MAP[event.keycode]
		_spawn_enemy_now(enemy_type, overManager.turn)
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("[DEBUG] Spawned enemy %s at wave %d" % [_enemy_debug_name(enemy_type), overManager.turn])
		return true

	if event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD or event.keycode == KEY_EQUAL:
		overManager.turn += 1
		_sync_wave_label()
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("[DEBUG] Wave set to %d" % overManager.turn)
		return true

	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		overManager.turn = max(0, overManager.turn - 1)
		_sync_wave_label()
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("[DEBUG] Wave set to %d" % overManager.turn)
		return true

	return false


func _sync_wave_label() -> void:
	if $UI.has_method("sync_wave_display"):
		$UI.sync_wave_display()

func spawn_wave(wave_idx):
	if not ongoing_wave:
		spawning_enemies = true
		ongoing_wave = true
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("\n=== WAVE %d START ===" % wave_idx)
			print("[SPECIAL] Pending before processing: %s" % [pending_special_unlocks])
			print("[SPECIAL] Unlocked before processing: %s" % [_enemy_list_debug_names(unlocked_special_pool)])
		_process_pending_special_unlocks(wave_idx)
		_schedule_next_special_pick(wave_idx)
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("[SPECIAL] Pending after processing/pick: %s" % [pending_special_unlocks])
			print("[SPECIAL] Selected set: %s" % [_enemy_list_debug_names(selected_specials)])
		var wave_data = Data.get_wave_data(wave_idx)
		var total_budget: int = wave_data["credits"]
		var credits: int = total_budget
		var pool: Array = _build_spawn_pool(wave_data["pool"])
		var delay: float = wave_data["delay"]

		# Build spawn list by spending credits
		var enemy_list: Array = []
		var available_specials: Array[Data.Enemy] = []
		for enemy_type in pool:
			if bool(Data.ENEMY_DATA[enemy_type].get("is_special", false)) and enemy_type not in available_specials:
				available_specials.append(enemy_type)

		# Ensure each available special appears at least once per wave.
		for special_type in available_specials:
			credits -= int(Data.ENEMY_DATA[special_type]["spawn_cost"])
			enemy_list.append(special_type)

		var basic_spent: int = 0
		var enforce_basic_cap: bool = pool.size() >= 3
		var basic_spend_cap: int = int(floor(float(total_budget) * Data.BASIC_ENEMY_CREDIT_CAP_RATIO))
		while credits > 0:
			# Filter pool to affordable enemies
			var affordable: Array = []
			var total_weight: int = 0
			for enemy_type in pool:
				var spawn_cost: int = int(Data.ENEMY_DATA[enemy_type]["spawn_cost"])
				if spawn_cost > credits:
					continue
				if enforce_basic_cap and enemy_type == Data.Enemy.DEFAULT and basic_spent + spawn_cost > basic_spend_cap:
					continue
				affordable.append(enemy_type)
				total_weight += Data.ENEMY_DATA[enemy_type]['spawn_weight']
			if affordable.is_empty():
				break
			# Weighted random pick
			var roll: int = randi() % total_weight
			var picked = affordable[0]
			for enemy_type in affordable:
				roll -= Data.ENEMY_DATA[enemy_type]['spawn_weight']
				if roll < 0:
					picked = enemy_type
					break
			credits -= int(Data.ENEMY_DATA[picked]["spawn_cost"])
			if picked == Data.Enemy.DEFAULT:
				basic_spent += int(Data.ENEMY_DATA[picked]["spawn_cost"])
			enemy_list.append(picked)

		enemy_list.shuffle()

		await _spawn_enemies_with_delay(enemy_list, delay, wave_idx)
		spawning_enemies = false

func _spawn_enemies_with_delay(enemy_types: Array, delay: float, wave_idx: int) -> void:
	for enemy_type in enemy_types:
		_spawn_enemy_now(enemy_type, wave_idx)
		await get_tree().create_timer(delay).timeout


func _spawn_enemy_now(enemy_type: Data.Enemy, wave_idx: int, path_progress: float = 0.0) -> void:
	var path_follow := PathFollow2D.new()
	path_follow.progress = path_progress
	var enemy := enemy_scene.instantiate()
	enemy.setup(path_follow, enemy_type, wave_idx)
	enemy.special_death_effect.connect(_on_enemy_special_death_effect)
	path_follow.add_child(enemy)
	$Path2D.add_child(path_follow)


func _process(_delta):
	if get_tree().get_nodes_in_group("enemies").size() == 0 and not spawning_enemies and ongoing_wave == true:
		ongoing_wave = false
		$UI.enable_wave_button()


func _on_tower_footprint_area_entered(_area):
	valid_placement = false


func _on_tower_footprint_area_exited(_area):
	if $"BG/TowerPreview/Tower Footprint".get_overlapping_areas().size() == 0:
		valid_placement = true


func _on_ui_closemenu():
	tower_menu = false
	current_tower = null


func _enemy_debug_name(enemy_type: Data.Enemy) -> String:
	var texture_path := String(Data.ENEMY_DATA[enemy_type].get("texture", "enemy_unknown"))
	return texture_path.get_file().get_basename()


func _enemy_list_debug_names(enemy_list: Array) -> Array[String]:
	var names: Array[String] = []
	for enemy_type in enemy_list:
		names.append(_enemy_debug_name(enemy_type))
	return names


func _schedule_next_special_pick(current_wave: int) -> void:
	# Every 5 waves (starting at wave 5), pick one unique special and schedule its unlock
	if current_wave >= Data.SPECIAL_PICK_START_WAVE and (current_wave - Data.SPECIAL_PICK_START_WAVE) % Data.SPECIAL_PICK_INTERVAL == 0:
		# Find unselected enemies from the pool
		var available_specials: Array[Data.Enemy] = []
		for enemy_type in Data.SPECIAL_ENEMY_POOL:
			if enemy_type not in selected_specials:
				available_specials.append(enemy_type)
		
		if available_specials.is_empty():
			print("Warning: All special enemies have been selected!")
			return
		
		# Pick random unselected special
		var picked_special = available_specials[randi() % available_specials.size()]
		selected_specials.append(picked_special)
		
		# Schedule unlock for 2 waves from now
		var unlock_wave = current_wave + Data.SPECIAL_PREP_DELAY
		pending_special_unlocks.append({"enemy_type": picked_special, "unlock_wave": unlock_wave})
		
		# Emit warning
		special_enemy_approaching.emit(picked_special, unlock_wave)
		if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
			print("[SPECIAL] Picked %s (enum=%d) on wave %d, unlocks on wave %d" % [_enemy_debug_name(picked_special), picked_special, current_wave, unlock_wave])
			print("[SPECIAL] Selected so far: %s" % [_enemy_list_debug_names(selected_specials)])


func _process_pending_special_unlocks(current_wave: int) -> void:
	# Move pending specials whose unlock_wave has been reached into the active pool
	var to_remove: Array[int] = []
	for i in range(pending_special_unlocks.size()):
		var entry = pending_special_unlocks[i]
		if current_wave >= entry["unlock_wave"]:
			unlocked_special_pool.append(entry["enemy_type"])
			to_remove.append(i)
			if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
				print("[SPECIAL] Unlocked %s at wave %d" % [_enemy_debug_name(entry["enemy_type"]), current_wave])
	
	# Remove in reverse order to preserve indices
	for idx in range(to_remove.size() - 1, -1, -1):
		pending_special_unlocks.remove_at(to_remove[idx])

	if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER and not to_remove.is_empty():
		print("[SPECIAL] Active unlocked pool: %s" % [_enemy_list_debug_names(unlocked_special_pool)])


func _build_spawn_pool(base_pool: Array) -> Array:
	# Return base pool plus any unlocked special enemies
	var combined_pool = base_pool.duplicate()
	combined_pool.append_array(unlocked_special_pool)
	if DEBUG_ACTIVE and DEBUG_SPECIAL_SCHEDULER:
		print("[SPECIAL] Spawn pool built. Base=%s UnlockedSpecial=%s Final=%s" % [
			_enemy_list_debug_names(base_pool),
			_enemy_list_debug_names(unlocked_special_pool),
			_enemy_list_debug_names(combined_pool)
		])
	return combined_pool


func _on_special_enemy_approaching(enemy_type: Data.Enemy, unlock_wave: int) -> void:
	# Forward approaching warning to UI
	$UI.show_special_enemy_approaching(enemy_type, unlock_wave)


func _on_enemy_special_death_effect(_effect_id: String, _payload: Dictionary) -> void:
	match _effect_id:
		"spawn_on_death":
			_spawn_children_from_death(_payload)
		"death_disable_pulse":
			_disable_nearby_towers(_payload)
		"death_speed_boost":
			_boost_nearby_enemies(_payload)
		_:
			pass


func _spawn_children_from_death(_payload: Dictionary) -> void:
	var spawn_enemy_type: Data.Enemy = int(_payload.get("spawn_enemy_type", Data.Enemy.DEFAULT))
	var spawn_count: int = int(_payload.get("spawn_count", 0))
	var spawn_delay: float = float(_payload.get("spawn_delay", 0.0))
	var path_progress: float = float(_payload.get("path_progress", 0.0))
	var wave_idx: int = int(_payload.get("wave_idx", 0))

	if spawn_count <= 0:
		return

	_spawn_children_from_death_async(spawn_enemy_type, spawn_count, spawn_delay, path_progress, wave_idx)


func _disable_nearby_towers(_payload: Dictionary) -> void:
	var origin: Vector2 = _payload.get("origin", Vector2.ZERO)
	var pulse_radius: float = float(_payload.get("pulse_radius", 0.0))
	var disable_duration: float = float(_payload.get("disable_duration", 0.0))

	if pulse_radius <= 0.0 or disable_duration <= 0.0:
		return

	for tower in $Towers.get_children():
		if tower is Tower and tower.global_position.distance_to(origin) <= pulse_radius:
			tower.apply_temporary_disable(disable_duration)

	_spawn_disable_pulse_visual(origin, pulse_radius)


func _boost_nearby_enemies(_payload: Dictionary) -> void:
	var origin: Vector2 = _payload.get("origin", Vector2.ZERO)
	var boost_radius: float = float(_payload.get("boost_radius", 0.0))
	var boost_duration: float = float(_payload.get("boost_duration", 0.0))
	var boost_mult: float = float(_payload.get("boost_mult", 1.0))

	if boost_radius <= 0.0 or boost_duration <= 0.0 or boost_mult <= 1.0:
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Area2D and enemy.global_position.distance_to(origin) <= boost_radius:
			if enemy.has_method("apply_external_speed_boost"):
				enemy.apply_external_speed_boost(boost_mult, boost_duration)


func _spawn_children_from_death_async(spawn_enemy_type: Data.Enemy, spawn_count: int, spawn_delay: float, path_progress: float, wave_idx: int) -> void:
	var cumulative_offset: float = 0.0
	for i in range(spawn_count):
		if i > 0 and spawn_delay > 0.0:
			await get_tree().create_timer(spawn_delay).timeout
		var path_follow := PathFollow2D.new()
		cumulative_offset += randf_range(50.0, 100.0)
		path_follow.progress = max(0.0, path_progress - cumulative_offset)
		var enemy := enemy_scene.instantiate()
		enemy.setup(path_follow, spawn_enemy_type, wave_idx)
		enemy.special_death_effect.connect(_on_enemy_special_death_effect)
		path_follow.call_deferred("add_child", enemy)
		$Path2D.call_deferred("add_child", path_follow)


func _spawn_disable_pulse_visual(origin: Vector2, pulse_radius: float) -> void:
	var segment_count := 72
	var points := PackedVector2Array()
	for i in range(segment_count):
		var angle := TAU * float(i) / float(segment_count)
		points.append(Vector2.RIGHT.rotated(angle) * pulse_radius)

	# Soft filled disk to make the affected area obvious.
	var fill := Polygon2D.new()
	fill.polygon = points
	fill.color = Color(0.2, 0.85, 1.0, 0.22)
	fill.global_position = origin
	add_child(fill)

	# Main ring carries the strongest contrast.
	var ring := Line2D.new()
	ring.points = points
	ring.width = 7.0
	ring.default_color = Color(0.4, 0.95, 1.0, 1.0)
	ring.closed = true
	ring.antialiased = true
	ring.global_position = origin
	add_child(ring)

	# Thin bright highlight ring improves readability on light backgrounds.
	var highlight := Line2D.new()
	highlight.points = points
	highlight.width = 2.0
	highlight.default_color = Color(1.0, 1.0, 1.0, 0.95)
	highlight.closed = true
	highlight.antialiased = true
	highlight.global_position = origin
	add_child(highlight)

	fill.scale = Vector2(0.02, 0.02)
	ring.scale = Vector2(0.02, 0.02)
	highlight.scale = Vector2(0.02, 0.02)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fill, "scale", Vector2.ONE, 0.65)
	tween.tween_property(ring, "scale", Vector2(1.06, 1.06), 0.65)
	tween.tween_property(highlight, "scale", Vector2(1.1, 1.1), 0.65)
	tween.tween_property(fill, "modulate:a", 0.0, 0.65)
	tween.tween_property(ring, "modulate:a", 0.0, 0.65)
	tween.tween_property(highlight, "modulate:a", 0.0, 0.65)
	tween.finished.connect(fill.queue_free)
	tween.finished.connect(ring.queue_free)
	tween.finished.connect(highlight.queue_free)
