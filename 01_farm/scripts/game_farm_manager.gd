extends Node

#signal NewDay (day : int)
signal SetPlayerTool (tool : PlayerTools, seed : CropData)
signal HarvestCrop (crop : Crop)
signal ChangeSeedQuantity (crop_data : CropData, quantity : int)
signal money_changed(new_value)

#var day : int = 0
var money = 0 :
	set(value):
		money = value
		money_changed.emit(value)
	

var all_crop_data : Array[CropData] = [
	preload("res://01_farm/crops/corn.tres"),
	preload("res://01_farm/crops/tomato.tres")
]

var owned_seeds : Dictionary[CropData, int]
	

func _ready ():
	money = overManager.plant_money
	get_tree().scene_changed.connect(_on_change_scene)
	GameFarmManager._on_change_scene()
	print(owned_seeds)
func _on_change_scene ():
	#if get_node_or_null("res://01_farm/scenes/main.tscn") == null:
		#return
	for cd in all_crop_data:
		give_seed.call_deferred(cd, 2)
	money += 10
	overManager.set_new_turn.call_deferred()
	
func harvest_crop (crop : Crop):
	overManager.give_money_tower(crop.crop_data.sell_price)
	print("Harvested!")
	HarvestCrop.emit(crop)
	crop.queue_free()
	
func try_buy_seed (crop_data):
	if money < crop_data.seed_price:
		print(money)
		return
	
	money -= crop_data.seed_price
	owned_seeds[crop_data] += 1
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
	
	
func consume_seed (crop_data : CropData):
	owned_seeds[crop_data] -= 1
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
	
	
func give_seed (crop_data : CropData, amount : int):
	if owned_seeds.has(crop_data):
		owned_seeds[crop_data] += amount
	else:
		owned_seeds[crop_data] = amount
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
