class_name BuySeedButton
extends BaseButton

@export var crop_data : CropData

@onready var price_text : Label = $PriceText
#@onready var icon : TextureRect = $Icon

func _ready():
	#print("crop_data: ", crop_data)
	#print("price_text: ", price_text)
	#pressed.connect(_on_pressed)

	if not crop_data:
		return
	#print("seed_price: ", crop_data.seed_price)  # add this
	#print("sprites: ", crop_data.growth_sprites)  # add this
	price_text.text = "$" + str(crop_data.seed_price)
	#icon.texture = crop_data.growth_sprites[len(crop_data.growth_sprites)-1]
	

func _on_mouse_entered() :
	self_modulate = Color.GREEN_YELLOW


func _on_pressed() -> void:
	GameFarmManager.try_buy_seed(crop_data)
