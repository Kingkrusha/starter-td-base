extends CanvasLayer

signal place_tower(tower_type: Data.Tower)
signal start_wave(wave: int)
signal closemenu()
signal current_speed(timescale : float, tick_rate : int)
enum MenuState {CLOSED, OPEN}
const MENU_BUTTON_TEXTURES = {MenuState.CLOSED: {
	'normal': "res://graphics/ui/menu.png", 
	'pressed':"res://graphics/ui/menu.png" ,
	'hover':"res://graphics/ui/menu_hover.png"}
	,MenuState.OPEN: {
		'normal':"res://graphics/ui/close_normal.png",
		'pressed':"res://graphics/ui/close_normal.png",
		'hover': "res://graphics/ui/close_hover.png"}}
var current_state: MenuState = MenuState.CLOSED
var wave = overManager.turn
var game_speed: float = 1.0
var stored_speed: float = 1.0
var tower_card_scene = preload("res://scenes/ui/tower_card.tscn")
@onready var alert_icon : TextureButton = $Control/AlertIcon
@onready var alert_text_box: PanelContainer = $"Control/AlertIcon/Text Box"
@onready var alert_text_label: Label = $"Control/AlertIcon/Text Box/Text"

var current_started_wave: int = 0
var alert_flash_active: bool = false
var alert_flash_time: float = 0.0
var latest_special_enemy: Data.Enemy = Data.Enemy.DEFAULT
var latest_special_unlock_wave: int = -1
var has_alert_data: bool = false

func _ready():
	wave = overManager.turn
	current_started_wave = wave
	$Control/WaveButton.text = ("Start Wave")
	update_stats(Data.money,Data.health)
	if not Data.money_changed.is_connected(_on_tower_money_changed):
		Data.money_changed.connect(_on_tower_money_changed)
	if not Data.health_changed.is_connected(_on_tower_health_changed):
		Data.health_changed.connect(_on_tower_health_changed)
	if not overManager.NewTurn.is_connected(_on_turn_changed):
		overManager.NewTurn.connect(_on_turn_changed)
	if not Data.tower_constraints_changed.is_connected(_on_tower_constraints_changed):
		Data.tower_constraints_changed.connect(_on_tower_constraints_changed)
	change_button_texture(current_state)
	$Control/TowerCards/TowerCardsContainer.visible = false
	alert_icon.visible = false
	alert_text_box.visible = false
	alert_icon.pressed.connect(_on_alert_icon_pressed)
	for tower in Data.Tower.values():
		var tower_card = tower_card_scene.instantiate()
		tower_card.setup(tower)
		$Control/TowerCards/TowerCardsContainer.add_child(tower_card)
		tower_card.connect('press', tower_select)
	_on_tower_constraints_changed()


func _process(delta: float) -> void:
	if alert_flash_active:
		alert_flash_time += delta
		# Blink by toggling alpha so the icon appears/disappears while staying clickable.
		var blink_on := int(floor(alert_flash_time * 4.0)) % 2 == 0
		alert_icon.modulate = Color(1.0, 1.0, 1.0, 1.0 if blink_on else 0.0)
	else:
		alert_icon.modulate = Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not alert_text_box.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position
		var icon_rect := alert_icon.get_global_rect()
		var text_rect := alert_text_box.get_global_rect()
		if not icon_rect.has_point(click_pos) and not text_rect.has_point(click_pos):
			alert_text_box.visible = false


func tower_select(tower_enum: Data.Tower):
	place_tower.emit(tower_enum)


func update_stats(money: int, health: int):
	$Control/StatsContainer/PanelContainer2/HBoxContainer/MoneyLabel.text = str(money)
	$Control/StatsContainer/PanelContainer/HBoxContainer/HealthLabel.text = str(health)


func _on_wave_button_pressed():
	if $Control/WaveButton.disabled:
		return
	$Control/WaveButton.disabled = true
	overManager.set_new_turn()
	wave = overManager.turn
	var started_wave = wave
	start_wave.emit(started_wave)
	current_started_wave = started_wave
	$Control/WaveButton.text = ("Start Wave " + str(wave +1 ))

func change_button_texture(state: MenuState):
	$Control/TowerCards/MenuToggleButton.texture_normal = load(MENU_BUTTON_TEXTURES[state]['normal'])
	$Control/TowerCards/MenuToggleButton.texture_pressed = load(MENU_BUTTON_TEXTURES[state]['pressed'])
	$Control/TowerCards/MenuToggleButton.texture_hover = load(MENU_BUTTON_TEXTURES[state]['hover'])


func _on_menu_toggle_button_pressed():
	current_state = MenuState.CLOSED if current_state == MenuState.OPEN else MenuState.OPEN
	change_button_texture(current_state)
	$Control/TowerCards/TowerCardsContainer.visible = true if current_state == MenuState.OPEN else false

func _on_toggle_scene_button_pressed() -> void:
	if game_speed != 1.0:
		Engine.time_scale = 1.0
		game_speed = 1.0
	overManager.toggleMode.emit()


func _on_slow_down_pressed():
	#if stored_speed != game_speed:
		#game_speed = stored_speed
	match game_speed:
		1.0:
			game_speed = 0.5
			Engine.time_scale = 0.5
		2.0:
			game_speed = 1
			Engine.time_scale = 1
		4.0:
			game_speed = 2
			Engine.time_scale = 2
		8.0:
			game_speed = 4
			Engine.time_scale = 4
		16.0:
			game_speed = 8
			Engine.time_scale = 8
		0.5:
			game_speed = 16
			Engine.time_scale = 16
	if game_speed >= 8:
		Engine.physics_ticks_per_second = 180
	elif game_speed >= 2:
		Engine.physics_ticks_per_second = 120
	else:
		Engine.physics_ticks_per_second = 60
	if game_speed < 1.0:
		$Control/PanelContainer/VBoxContainer/SpeedLabel.text = (str(game_speed) + " X")
	else:
		$Control/PanelContainer/VBoxContainer/SpeedLabel.text = (str(int(game_speed)) + " X")
	current_speed.emit(Engine.time_scale, Engine.physics_ticks_per_second)

#func _on_pause_pressed():
	#if Engine.time_scale > 0:
		#stored_speed = Engine.time_scale
		#Engine.time_scale = 0
	#else:
		#Engine.time_scale = stored_speed
		
func _on_speed_up_pressed():
	#if stored_speed != game_speed:
		#game_speed = stored_speed
	match game_speed:
		1.0:
			game_speed = 2
			Engine.time_scale = 2
		2.0:
			game_speed = 4
			Engine.time_scale = 4
		4.0:
			game_speed = 8
			Engine.time_scale = 8
		8.0:
			game_speed = 16
			Engine.time_scale = 16
		16.0:
			game_speed = 0.5
			Engine.time_scale = 0.5
		0.5:
			game_speed = 1
			Engine.time_scale = 1
	if game_speed >= 8:
		Engine.physics_ticks_per_second = 150
	elif game_speed >= 2:
		Engine.physics_ticks_per_second = 180
	else:
		Engine.physics_ticks_per_second = 60
	if game_speed < 1.0:
		$Control/PanelContainer/VBoxContainer/SpeedLabel.text = (str(game_speed) + " X")
	else:
		$Control/PanelContainer/VBoxContainer/SpeedLabel.text = (str(int(game_speed)) + " X")


func show_tower_menu(tower: Tower):
	$Control/TowerMenu.setup(tower)
	$Control/TowerMenu.visible = true


func _on_tower_menu_close():
	closemenu.emit()


func enable_wave_button():
	$Control/WaveButton.disabled = false


func sync_wave_display() -> void:
	wave = overManager.turn
	$Control/WaveButton.text = ("Start Wave " + str(wave + 1))


func refresh_display() -> void:
	update_stats(Data.money, Data.health)
	sync_wave_display()


func _on_tower_money_changed(new_money: int) -> void:
	update_stats(new_money, Data.health)


func _on_tower_health_changed(new_health: int) -> void:
	update_stats(Data.money, new_health)


func _on_turn_changed(_turn: int) -> void:
	sync_wave_display()
	_on_tower_constraints_changed()


func _on_tower_constraints_changed() -> void:
	for tower_card in get_tree().get_nodes_in_group('TowerCard'):
		tower_card.toggle_active()
	if $Control/TowerMenu.visible and is_instance_valid($Control/TowerMenu.tower_ref):
		$Control/TowerMenu.setup($Control/TowerMenu.tower_ref)


func show_special_enemy_approaching(enemy_type: Data.Enemy, unlock_wave: int) -> void:
	latest_special_enemy = enemy_type
	latest_special_unlock_wave = unlock_wave
	has_alert_data = true
	alert_icon.visible = true

	# A newly scheduled special should re-arm flashing and hide the textbox until clicked.
	alert_text_box.visible = false
	alert_flash_active = true
	alert_flash_time = 0.0

	_update_alert_text()


func _on_alert_icon_pressed() -> void:
	if not has_alert_data:
		return
	alert_text_box.visible = not alert_text_box.visible
	if alert_text_box.visible:
		_update_alert_text()
		# Stop flashing once the info has been acknowledged.
		alert_flash_active = false


func _update_alert_text() -> void:
	if not has_alert_data:
		alert_text_label.text = "No special alerts yet."
		return

	var enemy_data: Dictionary = Data.ENEMY_DATA.get(latest_special_enemy, {})
	var description := String(enemy_data.get("special_description", "A special enemy is approaching."))
	var waves_until := latest_special_unlock_wave - current_started_wave

	if waves_until > 0:
		alert_text_label.text = "%s\nArrives in %d wave(s)." % [description, waves_until]
	else:
		# If already unlocked, keep showing latest enemy info but omit countdown text.
		alert_text_label.text = description
		
