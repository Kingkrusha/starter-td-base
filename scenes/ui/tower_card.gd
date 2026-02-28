extends Button

var id: Data.Tower = Data.Tower.BASIC
var cost:int 

signal press(tower_enum: Data.Tower)

func _ready():
	cost = Data.TOWER_DATA[id]['cost']
	$VBoxContainer/Control/VBoxContainer/HBoxContainer/CostLabel.text = str(cost)
	$VBoxContainer/Control/VBoxContainer/NameLabel.text = Data.TOWER_DATA[id]['name']
	toggle_active(Data.money)
	$VBoxContainer/TowerPreview/TextureRect.texture = load(Data.TOWER_DATA[id]['thumbnail'])

func setup(tower_enum: Data.Tower):
		id = tower_enum


func _on_pressed():
	press.emit(id)

func toggle_active(money: int):
	if cost > money:
		disabled = true
	elif cost <= money:
		disabled = false
