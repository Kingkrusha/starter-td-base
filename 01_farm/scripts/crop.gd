class_name Crop
extends Node2D

var crop_data : CropData
var days_until_grown : int
var watered : bool
var harvestable : bool
var tile_map_coords : Vector2i

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
	
	if days_until_grown != 1:
		print_debug(days_until_grown)
		days_until_grown -= 1
	else:
		print_debug("Harvest!")
		harvestable = true
	
	var sprite_count : int = len(crop_data.growth_sprites)
	var growth_percent : float = (crop_data.days_to_grow - days_until_grown) / float(crop_data.days_to_grow)	
	var index : int = floor(growth_percent * sprite_count)
	index = clamp(index, 0, sprite_count - 1)
	
	sprite.texture = crop_data.growth_sprites[index]
