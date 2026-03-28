class_name Crop
extends Node2D

var crop_data : CropData
var days_until_grown : int
var watered : bool
var harvestable : bool
var tile_map_coords : Vector2i
var sell_price : int

@onready var sprite : Sprite2D = $Sprite 

func _ready ():
	overManager.NewTurn.connect(_on_new_day)
	
func _set_crop (data : CropData, already_watered: bool, tile_coords: Vector2i) :
	crop_data = data
	watered = already_watered
	tile_map_coords = tile_coords
	harvestable = false
	
	days_until_grown = data.days_to_grow
	sprite.texture = crop_data.growth_sprites[0]
	
func _on_new_day (_day:int):
	if not watered:
		return
	watered = false
	
	var sprite_count : int = len(crop_data.growth_sprites)
	var growth_percent : float = (crop_data.days_to_grow - days_until_grown) / float(crop_data.days_to_grow)	
	var index : int = floor(growth_percent * sprite_count)
	index = clamp(index, 0, sprite_count - 1)
	
	sprite.texture = crop_data.growth_sprites[index]
	print_debug(index)
	
	if index == 0:
		print_debug(days_until_grown)
		days_until_grown -= 1
	elif index == 1:
		print_debug("First Stage")
		harvestable = true
		sell_price = crop_data.sell_price_initial
		days_until_grown -= 1
	elif index == 2 :
		print_debug("Second Stage")
		harvestable = true
		sell_price = crop_data.sell_price_second
		days_until_grown -= 1
	elif index == 3 :
		print_debug("Third Stage")
		harvestable = true
		sell_price = crop_data.sell_price_third
		days_until_grown -= 1
	else:
		print_debug("Final Stage")
		harvestable = true
		sell_price = crop_data.sell_price_final
		
		
	
	
