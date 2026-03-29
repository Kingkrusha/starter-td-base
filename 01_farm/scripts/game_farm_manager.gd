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
		print("Current Val: ", money)
		money_changed.emit(money)
	
		
	
	

var all_crop_data : Array[CropData] = [
	#preload("res://01_farm/crops/corn.tres"),
	#preload("res://01_farm/crops/tomato.tres"),
	preload("res://01_farm/crops/blackberry.tres"),
	preload("res://01_farm/crops/firecracker.tres"),
	preload("res://01_farm/crops/mushroom.tres"),
	preload("res://01_farm/crops/pumpkin.tres")
]

var owned_seeds : Dictionary[CropData, int] = {}
	

func _ready ():
	#overManager.ChangeFarmMoney.connect(update_money)
	get_tree().scene_changed.connect(_on_change_scene)
	GameFarmManager._on_change_scene()
	#print(owned_seeds)

#func update_money(new_money : int):
	#money = new_money
	
func _on_change_scene ():
	#if get_node_or_null("res://01_farm/scenes/main.tscn") == null:
		#return
	for cd in all_crop_data:
		give_seed.call_deferred(cd, 2)
	money += 10
	
func harvest_crop (crop : Crop, reward : int):
	overManager.give_money_tower(reward)
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
