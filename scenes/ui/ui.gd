extends CanvasLayer

signal place_tower(tower_type: Data.Tower)
signal start_wave(wave: int)
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
var wave:int = 0
var game_speed: float = 1.0
var stored_speed: float = 1.0
var tower_card_scene = preload("res://scenes/ui/tower_card.tscn")

func _ready():
	update_stats(Data.money,Data.health)
	change_button_texture(current_state)
	$Control/TowerCards/TowerCardsContainer.visible = false
	for tower in Data.Tower.values():
		var tower_card = tower_card_scene.instantiate()
		tower_card.setup(tower)
		$Control/TowerCards/TowerCardsContainer.add_child(tower_card)
		tower_card.connect('press', tower_select)


func tower_select(tower_enum: Data.Tower):
	place_tower.emit(tower_enum)

func update_stats(money: int, health: int):
	$Control/StatsContainer/PanelContainer2/HBoxContainer/MoneyLabel.text = str(money)
	$Control/StatsContainer/PanelContainer/HBoxContainer/HealthLabel.text = str(health)


func _on_wave_button_pressed():
	start_wave.emit(wave)
	wave += 1

func change_button_texture(state: MenuState):
	$Control/TowerCards/MenuToggleButton.texture_normal = load(MENU_BUTTON_TEXTURES[state]['normal'])
	$Control/TowerCards/MenuToggleButton.texture_pressed = load(MENU_BUTTON_TEXTURES[state]['pressed'])
	$Control/TowerCards/MenuToggleButton.texture_hover = load(MENU_BUTTON_TEXTURES[state]['hover'])


func _on_menu_toggle_button_pressed():
	current_state = MenuState.CLOSED if current_state == MenuState.OPEN else MenuState.OPEN
	change_button_texture(current_state)
	$Control/TowerCards/TowerCardsContainer.visible = true if current_state == MenuState.OPEN else false



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
