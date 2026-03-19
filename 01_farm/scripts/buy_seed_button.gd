class_name BuySeedButton
extends BaseButton

@export var crop_data : CropData

@onready var price_text : Label = $PriceText
@onready var icon : TextureRect = $Icon

func _ready():
	pressed.connect(_on_pressed)

	if not crop_data:
		return
	
	price_text.text = "$" + str(crop_data.seed_price)
	icon.texture = crop_data.growth_sprites[len(crop_data.growth_sprites)-1]

func _on_pressed():
	GameFarmManager.try_buy_seed(crop_data)
