extends TextureButton

@export var tool : PlayerTools.Tool
@export var seed : CropData
@onready var seed_bar = $"../../Plant Inventory/HBoxContainer"
@onready var icon : TextureRect = $SeedIcon
var my_texture 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seed_bar.visible = false
	pivot_offset = size /2
	GameFarmManager.SetPlayerTool.connect(change_icon)
	my_texture = preload("res://01_farm/Sprites/Crops/Tomato/tomato_growth_0.tres")


func _on_toggled(toggled_on: bool) -> void:
	if button_pressed:
		seed_bar.visible = true
		#GameFarmManager.SetPlayerTool.emit(tool, seed)
		self_modulate = Color.ROSY_BROWN
	else:
		seed_bar.visible = false
		self_modulate = Color.WHITE

func change_icon(tool, plant):
	#print("tool: ", tool)
	#print("Plant: ", plant)
	if tool == 3:
		if plant == null:
			return
		if icon == null:
			push_error("Icon node not found!")
			return
		icon.texture = plant.growth_sprites[plant.growth_sprites.size() - 1]
	else:
		icon.texture = my_texture
func _on_mouse_entered() -> void:
	scale.x = 1.05
	scale.y = 1.05


func _on_mouse_exited() -> void:
	scale.x = 1
	scale.y = 1
#
#func _on_pressed():
	#seed_bar.visible = !seed_bar.visible
	
