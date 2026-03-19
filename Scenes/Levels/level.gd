extends Node2D

var enemy_scene = preload("res://scenes/Enemies/enemy.tscn")
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
signal enable_wave_button()

func _ready() -> void:
	RenderingServer.set_default_clear_color('#e0f6f4')
	$UI.connect("start_wave", spawn_wave)
	#$"Player Camera".limit_bottom = $Background/WorldBounds/Bottom.global_position.y
	#$"Player Camera".limit_top = $Background/WorldBounds/Top.global_position.y
	#$"Player Camera".limit_left = $Background/WorldBounds/Left.global_position.x
	#$"Player Camera".limit_right = $Background/WorldBounds/Right.global_position.x


func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet, tower_ref: Node = null):
	if bullet_enum == Data.Bullet.SINGLE:
		var bullet = bullet_scene.instantiate()
		bullet.setup(pos, angle, bullet_enum, tower_ref)
		$Bullets.add_child(bullet)

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
		bomb.setup(pos, angle, bullet_enum, tower_ref)
		$Bullets.add_child(bomb)


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
	var raw_pos = get_local_mouse_position()
	#var pos = Vector2i(raw_pos.x / 16, raw_pos.y /16)
	var pos = Vector2i(raw_pos.x, raw_pos.y)
	$BG/TowerPreview.modulate = Color.RED if not valid_placement else Color.WHITE
	if event is InputEventMouseButton and event.button_mask == 1 and place_tower:
		#var tile_data =($BG/TileMapLayer.get_cell_tile_data(pos))
		if event.button_index == 1 and valid_placement == true: #and pos not in used_cells and tile_data is TileData and tile_data.get_custom_data("useable"):
			#used_cells.append(pos)
			var tower = load(tower_scenes[selected_tower]).instantiate()
			tower.position = pos #*16 + Vector2i(8,8)
			tower.connect('shoot', create_bullet)
			tower.connect('select', tower_selection)
			$Towers.add_child(tower)
			place_tower = false
			Data.money -= Data.TOWER_DATA[selected_tower]['cost']
	
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

func spawn_wave(wave_idx):
	if not ongoing_wave:
		spawning_enemies = true
		ongoing_wave = true
		var wave_data = Data.get_wave_data(wave_idx)
		var credits: int = wave_data["credits"]
		var pool: Array = wave_data["pool"]
		var delay: float = wave_data["delay"]

		# Build spawn list by spending credits
		var enemy_list: Array = []
		var boss_list: Array = []
		while credits > 0:
			# Filter pool to affordable enemies
			var affordable: Array = []
			var total_weight: int = 0
			for enemy_type in pool:
				if Data.ENEMY_DATA[enemy_type]['spawn_cost'] <= credits:
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
			credits -= Data.ENEMY_DATA[picked]['spawn_cost']
			if picked == Data.Enemy.BOSS:
				boss_list.append(picked)
			else:
				enemy_list.append(picked)

		enemy_list.shuffle()

		await _spawn_enemies_with_delay(enemy_list, delay, wave_idx)
		await _spawn_enemies_with_delay(boss_list, delay, wave_idx)
		spawning_enemies = false

func _spawn_enemies_with_delay(enemy_types: Array, delay: float, wave_idx: int) -> void:
	for enemy_type in enemy_types:
		var path_follow = PathFollow2D.new()
		var enemy = enemy_scene.instantiate()
		enemy.setup(path_follow, enemy_type, wave_idx)
		path_follow.add_child(enemy)
		$Path2D.add_child(path_follow)
		await get_tree().create_timer(delay).timeout


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
