extends Node

signal NewDay (day : int)
signal SetPlayerTool (tool : PlayerTools, seed : CropData)
signal HarvestCrop (crop : Crop)
signal ChangeSeedQuantity (crop_data : CropData, quantity : int)
signal ChangeMoney (money : int)

var day : int = 0
var money : int = 0

var all_crop_data : Array[CropData] = [
	preload("res://01_farm/crops/corn.tres"),
	preload("res://01_farm/crops/tomato.tres")
]

var owned_seeds : Dictionary[CropData, int]

func _ready ():
	get_tree().scene_changed.connect(_on_change_scene)
	
	if get_tree().current_scene.name == "main":
		_on_change_scene()
	

func _on_change_scene ():
	if get_tree().current_scene.name != "main":
		return
	for cd in all_crop_data:
		give_seed.call_deferred(cd, 2)
	give_money.call_deferred(10)
	set_next_day.call_deferred()
	
func set_next_day ():
	day += 1
	NewDay.emit(day)

func harvest_crop (crop : Crop):
	give_money(crop.crop_data.sell_price)
	HarvestCrop.emit(crop)
	crop.queue_free()
	
func try_buy_seed (crop_data):
	if money < crop_data.seed_price:
		return
	
	money -= crop_data.seed_price
	owned_seeds[crop_data] += 1
	ChangeMoney.emit(money)
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
	
	
func consume_seed (crop_data : CropData):
	owned_seeds[crop_data] -= 1
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
	
func give_money (amount : int):
	money += amount
	ChangeMoney.emit(money)
func give_seed (crop_data : CropData, amount : int):
	if owned_seeds.has(crop_data):
		owned_seeds[crop_data] += amount
	else:
		owned_seeds[crop_data] = amount
	ChangeSeedQuantity.emit(crop_data, owned_seeds[crop_data])
