extends Button

var id: Data.Tower = Data.Tower.BASIC
var cost:int 

signal press(tower_enum: Data.Tower)

func _ready():
	cost = Data.TOWER_DATA[id]['cost']
	$VBoxContainer/Control/VBoxContainer/CostBox/CostLabel.text = str(cost)
	$VBoxContainer/Control/VBoxContainer/NameLabel.text = Data.TOWER_DATA[id]['name']
	toggle_active()
	$VBoxContainer/TowerPreview/TextureRect.texture = load(Data.TOWER_DATA[id]['thumbnail'])

func setup(tower_enum: Data.Tower):
		id = tower_enum


func _on_pressed():
	press.emit(id)

func toggle_active(_money: int = 0):
	var gate: Dictionary = Data.can_place_tower_from_plants(id)
	disabled = not bool(gate.get("allowed", false))
	if disabled:
		tooltip_text = String(gate.get("reason", "Cannot place this tower."))
	else:
		tooltip_text = ""
