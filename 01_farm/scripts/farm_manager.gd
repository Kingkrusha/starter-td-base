class_name FarmManager
extends Node

enum TileType
{
	GRASS,
	TILLED,
	TILLED_WATERED
}

class TileInfo:
	var tilled : bool
	var watered : bool
	var crop : Crop

@onready var tile_map : TileMapLayer = $FarmTileMap
var tile_info : Dictionary[Vector2i,TileInfo]
var crop_scene: PackedScene = preload("res://01_farm/scenes/crop.tscn")

var tile_atlas_coords : Dictionary[TileType, Vector2i] = {
	TileType.GRASS: Vector2i(0,0),
	TileType.TILLED: Vector2i(1,0),
	TileType.TILLED_WATERED: Vector2i(0, 1)
}

@onready var till_sound : AudioStreamPlayer = $TillSound
@onready var water_sound : AudioStreamPlayer = $WaterSound
@onready var plant_seed_sound : AudioStreamPlayer = $PlantSeedSound
@onready var harvest_sound : AudioStreamPlayer = $HarvestSound
func _ready ():
	GameFarmManager.NewDay.connect(_on_new_day)
	GameFarmManager.HarvestCrop.connect(_on_harvest_crop)
	for cell in tile_map.get_used_cells():
		tile_info[cell] = TileInfo.new()
		
func _on_new_day (day: int):
	for tile_pos in tile_map.get_used_cells():
		if  tile_info[tile_pos].watered:
			_set_tile_state(tile_pos, TileType.TILLED)
		elif tile_info[tile_pos].tilled:
			if tile_info[tile_pos].crop == null:
				_set_tile_state(tile_pos, TileType.GRASS)
				
func _on_harvest_crop(crop : Crop):
	tile_info[crop.tile_map_coords].crop = null
	_set_tile_state(crop.tile_map_coords, TileType.TILLED)

func try_till_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	
	if tile_info[coords].crop:
		return
	if tile_info[coords].tilled:
		return
	_set_tile_state(coords, TileType.TILLED)
	till_sound.play()

func try_water_tile(player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)

	# return if the tile is not tilled
	if not tile_info[coords].tilled:
		print(tile_info[coords].watered)
		return

	_set_tile_state(coords, TileType.TILLED_WATERED)
	water_sound.play()

	# if there's a crop on the tile, water it
	if tile_info[coords].crop:
		tile_info[coords].crop.watered = true
func try_seed_tile (player_pos : Vector2, crop_data :CropData):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	
	if not tile_info[coords].tilled:
		return
	if tile_info[coords].crop:
		return
	if GameFarmManager.owned_seeds[crop_data] <= 0:
		return
	
	var crop : Crop = crop_scene.instantiate()
	add_child(crop)
	crop.global_position = tile_map.map_to_local(coords)
	crop._set_crop(crop_data, is_tile_watered(coords), coords)
	
	tile_info[coords].crop = crop
	
	GameFarmManager.consume_seed(crop_data)
	plant_seed_sound.play()

func try_harvest_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	
	if not tile_info[coords].crop:
		return
	
	if not tile_info[coords].crop.harvestable:
		return
	
	GameFarmManager.harvest_crop(tile_info[coords].crop)
	tile_info[coords].crop = null
	harvest_sound.play()

func is_tile_watered (pos :Vector2) -> bool:
	var coords : Vector2i = tile_map.local_to_map(pos)
	return tile_info[coords].watered
	
func _set_tile_state (coords :Vector2i, tile_type : TileType):
	tile_map.set_cell(coords, 0, tile_atlas_coords[tile_type])
	match tile_type:
		TileType.GRASS:
			tile_info[coords].tilled = false
			tile_info[coords].watered = false
		TileType.TILLED:
			tile_info[coords].tilled = true
			tile_info[coords].watered = false
		TileType.TILLED_WATERED:
			tile_info[coords].tilled = true
			tile_info[coords].watered = true
