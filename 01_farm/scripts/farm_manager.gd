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
@onready var plantNode : Node2D = %Plants
@onready var tile_map : TileMapLayer = $FarmTileMap
var tile_info : Dictionary[Vector2i,TileInfo]
var crop_scene: PackedScene = preload("res://01_farm/scenes/crop.tscn")

var plant_info : Dictionary[String,int] = {
	"pepper" : 0,
	"pepperIndex": 0,
	"blackberry" : 0,
	"blackberryIndex": 0,
	"mushroom": 0,
	"mushroomIndex":0,
	"pineapple":0,
	"pineappleIndex":0,
	"pumpkin":0,
	"pumpkinIndex":0
}

var tile_atlas_coords : Dictionary[TileType, Array] = {
	TileType.GRASS: [1,Vector2i(9,10)],
	TileType.TILLED: [3, Vector2i(0,3)],
	TileType.TILLED_WATERED: [3, Vector2i(0, 7)]
}
@onready var till_sound : AudioStreamPlayer = $TillSound
@onready var water_sound : AudioStreamPlayer = $WaterSound
@onready var plant_seed_sound : AudioStreamPlayer = $PlantSeedSound
@onready var harvest_sound : AudioStreamPlayer = $HarvestSound
func _ready ():
	#GameFarmManager.NewDay.connect(_on_new_day)
	overManager.NewTurn.connect(_on_new_day)
	GameFarmManager.HarvestCrop.connect(_on_harvest_crop)
	overManager.toggleMode.connect(track_plants_num)
	overManager.toggleMode.connect(track_plants_index)
	tile_info = {}
	for cell in tile_map.get_used_cells():
		tile_info[cell] = TileInfo.new()
	
	#create_starting_crops(Vector2i(0, 4), preload("res://01_farm/crops/hot_pepper.tres"), 2)
	track_plants_num()
	track_plants_index()
	Data.notify_tower_constraint_state_changed()

func create_starting_crops(tile_coords: Vector2i, crop_data: CropData, starting_point: int):
	 # Create crop
	var new_crop : Crop = crop_scene.instantiate() 
	add_child(new_crop)
	new_crop.add_to_group("crops")
	print("Sprite is: ",  starting_point)
	# Configure through crop helper so instance state stays consistent.
	new_crop._set_crop(crop_data, false, tile_coords)
	if starting_point > 0:
		new_crop._apply_growth_stage(starting_point)
	_set_tile_state(tile_coords, TileType.TILLED)
	
	# Set sprite
	#var growth_index = crop_data.days_to_grow - days_left
	#growth_index = clamp(growth_index, 0, crop_data.growth_sprites.size() - 1)
	new_crop.sprite.texture = crop_data.growth_sprites[new_crop.growth_stage]
	
	# Position
	new_crop.position = tile_map.map_to_local(tile_coords)
	
	# Update tile info
	if tile_info.has(tile_coords):
		tile_info[tile_coords].crop = new_crop
		_set_tile_state(tile_coords, TileType.TILLED)
	
func _get_tile_info(coords: Vector2i) -> TileInfo:
	return tile_info.get(coords, null)
		
func _on_new_day (day: int):
	print("New Day!")
	for tile_pos in tile_map.get_used_cells():
		var info := _get_tile_info(tile_pos)
		if info.watered:
			_set_tile_state(tile_pos, TileType.TILLED)
		elif info.tilled:
			if info.crop == null:
				_set_tile_state(tile_pos, TileType.GRASS)
	Data.notify_tower_constraint_state_changed.call_deferred()
				
func _on_harvest_crop(crop : Crop):
	_get_tile_info(crop.tile_map_coords).crop = null
	_set_tile_state(crop.tile_map_coords, TileType.TILLED)
	Data.notify_tower_constraint_state_changed()

func try_till_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if info == null:
		return
	if info.crop:
		return
	if info.tilled:
		return
	
	
	_set_tile_state(coords, TileType.TILLED)
	till_sound.play()

func try_water_tile(player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)

	if info == null:
		return
	if not info.tilled:
		
		return

	_set_tile_state(coords, TileType.TILLED_WATERED)
	water_sound.play()

	# if there's a crop on the tile, water it
	if info.crop:
		#print_debug(info.crop)
		info.crop.watered = true
		
func try_seed_tile (player_pos : Vector2, crop_data :CropData):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if info == null:
		return
	if not info.tilled:
		return
	if info.crop:
		return
	if not GameFarmManager.owned_seeds.has(crop_data) or GameFarmManager.owned_seeds[crop_data] <= 0:
		return
	
	var crop : Crop = crop_scene.instantiate()
	add_child(crop)
	crop.add_to_group("crops")
	crop.global_position = tile_map.map_to_local(coords)
	crop._set_crop(crop_data, is_tile_watered(coords), coords)
	
	info.crop = crop
	
	GameFarmManager.consume_seed(crop_data)
	plant_seed_sound.play()
	Data.notify_tower_constraint_state_changed()

func try_harvest_tile (player_pos : Vector2):
	var coords : Vector2i = tile_map.local_to_map(player_pos)
	var info := _get_tile_info(coords)
	
	if info == null:
		return
	if not info.crop:
		return
	
	if not tile_info[coords].crop.harvestable:
		print_debug("Whoops!")
		return

	var harvest_gate: Dictionary = Data.can_harvest_crop_for_towers(tile_info[coords].crop)
	if not bool(harvest_gate.get("allowed", false)):
		print(String(harvest_gate.get("reason", "Cannot harvest this crop right now.")))
		return
	
	GameFarmManager.harvest_crop(tile_info[coords].crop, tile_info[coords].crop.sell_price)
	tile_info[coords].crop = null
	harvest_sound.play()
	Data.notify_tower_constraint_state_changed()

func is_tile_watered (pos :Vector2) -> bool:
	var coords : Vector2i = tile_map.local_to_map(pos)
	var info = _get_tile_info(coords)
	if info == null:
		return false
	return info.watered
	
func _set_tile_state (coords :Vector2i, tile_type : TileType):
	var info := _get_tile_info(coords)
	tile_map.set_cell(coords, tile_atlas_coords[tile_type][0], tile_atlas_coords[tile_type][1])
	match tile_type:
		TileType.GRASS:
			info.tilled = false
			info.watered = false
		TileType.TILLED:
			info.tilled = true
			info.watered = false
		TileType.TILLED_WATERED:
			tile_info[coords].tilled = true
			tile_info[coords].watered = true

func track_plants_num() -> Dictionary:
	var all_crops = get_tree().get_nodes_in_group("crops")
	var counts = {}
	for child in all_crops:
		if child is Crop && child.crop_data.growth_stage > 0:
			var crop_name = child.crop_data.crop_name
			counts[crop_name] = counts.get(crop_name, 0) +1
				
	overManager.plant_data.emit(counts)
	return counts

func track_plants_index() -> Dictionary:
	var all_crops = get_tree().get_nodes_in_group("crops")
	var indexCount = {}
	for child in all_crops:
		if child is Crop:
			var crop_name = child.crop_data.crop_name
			indexCount[crop_name] = indexCount.get(crop_name, 0) + child.growth_stage
	return(indexCount)
