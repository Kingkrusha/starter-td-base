extends Node

#signal NewDay (day : int)
signal SetPlayerTool (tool : PlayerTools, seed : CropData)
signal HarvestCrop (crop : Crop)
signal ChangeSeedQuantity (crop_data : CropData, quantity : int)
signal money_changed(new_value : int)

#var day : int = 0
var money : int = 0:
	set(value):
		money = value
		#print("Current Val: ", money)
		money_changed.emit(money)


var plant: Crop
#var plant_inv: int
#var plant_dict = {plant : plant_inv}

var all_crop_data : Array[CropData] = [
	preload("res://01_farm/crops/blackberry.tres"),
	preload("res://01_farm/crops/hot_pepper.tres"),
	preload("res://01_farm/crops/mushroom.tres"),
	preload("res://01_farm/crops/pumpkin.tres"),
	preload("res://01_farm/crops/pineapple.tres")
]

var owned_seeds : Dictionary[CropData, int] = {}
	

func _ready ():
	_on_change_scene()
	overManager.reset.connect(reset)
	#print(owned_seeds)
#func update_money(new_money : int):
	#money = new_money
	
func _on_change_scene ():
	print_debug("Called!")
	for cd in all_crop_data:
		give_seed.call_deferred(cd, 0)
		print(owned_seeds)
	money = 20
	
func harvest_crop (crop : Crop, reward : int):
	overManager.give_money_tower(reward)
	Data.record_plants_harvested()
	print("Harvested!")
	HarvestCrop.emit(crop)
	crop.queue_free()
	
func try_buy_seed (crop_data):
	if money < crop_data.seed_price:
		#print(money)
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

func reset():
	_on_change_scene.call_deferred()
	
