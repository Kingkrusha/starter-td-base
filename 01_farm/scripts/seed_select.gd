class_name SeedSelect
extends BaseButton

@export var tool : PlayerTools.Tool
@export var seed : CropData

@onready var quantity_text : Label = $QuantityText
@onready var icon : TextureRect = $Icon

func _ready():
	#print("seed_price: ", seed.seed_price)  # add this
	#print("Seeds: ", quantity_text)
	#print("sprites: ", seed.growth_sprites)
	icon.texture = seed.growth_sprites[len(seed.growth_sprites)-1]
	quantity_text.text = ""
	pivot_offset = size /2
	GameFarmManager.ChangeSeedQuantity.connect(_on_change_seed_quantity)

#func _on_mouse_entered() -> void:
	#modulate = Color.SEA_GREEN

func _on_change_seed_quantity (crop_data : CropData, quantity :  int):
	if seed != crop_data:
		return
		
	quantity_text.text = str(quantity)

func _on_pressed() -> void:
	#print (seed)
	GameFarmManager.SetPlayerTool.emit(tool, seed)
