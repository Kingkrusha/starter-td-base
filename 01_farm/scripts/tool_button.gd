class_name ToolButton
extends TextureButton

@export var tool : PlayerTools.Tool
@export var seed : CropData

@onready var quantity_text : Label = $QuantityText

func _ready():
	quantity_text.text = ""
	pivot_offset = size /2
	GameFarmManager.ChangeSeedQuantity.connect(_on_change_seed_quantity)


func _on_pressed() -> void:
	GameFarmManager.SetPlayerTool.emit(tool, seed)


func _on_mouse_entered() -> void:
	scale.x = 1.05
	scale.y = 1.05


func _on_mouse_exited() -> void:
	scale.x = 1
	scale.y = 1

func _on_change_seed_quantity (crop_data : CropData, quantity :  int):
	if seed != crop_data:
		return
		
	quantity_text.text = str(quantity)
