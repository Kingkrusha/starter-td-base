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
