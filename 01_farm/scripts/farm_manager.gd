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
	#GameFarmManager.NewDay.connect(_on_new_day)
	overManager.NewTurn.connect(_on_new_day)
	GameFarmManager.HarvestCrop.connect(_on_harvest_crop)
	tile_info = {}
	for cell in tile_map.get_used_cells():
		tile_info[cell] = TileInfo.new()

func _get_tile_info(coords: Vector2i) -> TileInfo:
	if not tile_info.has(coords):
		tile_info[coords] = TileInfo.new()
	return tile_info[coords]
		
func _on_new_day (day: int):
	for tile_pos in tile_map.get_used_cells():
		var info := _get_tile_info(tile_pos)
		if info.watered:
			_set_tile_state(tile_pos, TileType.TILLED)
		elif info.tilled:
			if info.crop == null:
				_set_tile_state(tile_pos, TileType.GRASS)
				
func _on_harvest_crop(crop : Crop):
	_get_tile_info(crop.tile_map_coords).crop = null
	_set_tile_state(crop.tile_map_coords, TileType.TILLED)

func try_till_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if info.crop:
		return
	if info.tilled:
		return
	_set_tile_state(coords, TileType.TILLED)
	till_sound.play()

func try_water_tile(player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)

	# return if the tile is not tilled
	if not info.tilled:
		return

	_set_tile_state(coords, TileType.TILLED_WATERED)
	water_sound.play()

	# if there's a crop on the tile, water it
	if info.crop:
		info.crop.watered = true
func try_seed_tile (player_pos : Vector2, crop_data :CropData):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if not info.tilled:
		return
	if info.crop:
		return
	if not GameFarmManager.owned_seeds.has(crop_data) or GameFarmManager.owned_seeds[crop_data] <= 0:
		return
	
	var crop : Crop = crop_scene.instantiate()
	add_child(crop)
	crop.global_position = tile_map.map_to_local(coords)
	crop._set_crop(crop_data, is_tile_watered(coords), coords)
	
	info.crop = crop
	
	GameFarmManager.consume_seed(crop_data)
	plant_seed_sound.play()

func try_harvest_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if not info.crop:
		return
	
	if not info.crop.harvestable:
		return
	
	GameFarmManager.harvest_crop(info.crop)
	info.crop = null
	harvest_sound.play()

func is_tile_watered (pos :Vector2) -> bool:
	var coords : Vector2i = tile_map.local_to_map(pos)
	return _get_tile_info(coords).watered
	
func _set_tile_state (coords :Vector2i, tile_type : TileType):
	var info := _get_tile_info(coords)
	tile_map.set_cell(coords, 0, tile_atlas_coords[tile_type])
	match tile_type:
		TileType.GRASS:
			info.tilled = false
			info.watered = false
		TileType.TILLED:
			info.tilled = true
			info.watered = false
		TileType.TILLED_WATERED:
			info.tilled = true
			info.watered = true
