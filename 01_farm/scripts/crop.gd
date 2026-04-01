class_name Crop
extends Node2D

var crop_data : CropData:
	set(value):
		crop_data = value
		_update_tooltip()
var days_until_grown : int
var watered : bool
var harvestable : bool
var tile_map_coords : Vector2i
var sell_price : int
var growth_stage: int = 0

@onready var sprite : Sprite2D = $Sprite 
@onready var node: Control = $Sprite/Control
func _ready ():
	overManager.NewTurn.connect(_on_new_day)
	node.position = Vector2(-8, -8)
	node.size = Vector2(16, 16)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_tooltip()
	
func _set_crop (data : CropData, already_watered: bool, tile_coords: Vector2i) :
	crop_data = data
	watered = already_watered
	tile_map_coords = tile_coords
	harvestable = false

	days_until_grown = data.days_to_grow
	growth_stage = 0
	_apply_growth_stage(0)

	# Any crop created before wave/day progression starts gets a free bump to stage 1.
	if overManager.turn == 0 and crop_data.growth_sprites.size() > 1 and growth_stage < 1:
		_apply_growth_stage(1)

	_update_tooltip()

func _update_tooltip():
	if crop_data == null:
		node.tooltip_text = ""
		return

	var crop_name := String(crop_data.crop_name).capitalize()
	var yield_value := int(sell_price)
	var max_stage = max(0, crop_data.growth_sprites.size() - 1)
	var stage_value := int(growth_stage)
	var tooltip := "%s, Yield %d, Growth stage %d" % [crop_name, yield_value, stage_value]

	if stage_value < max_stage:
		var progressed := int(crop_data.days_to_grow - days_until_grown)
		var next_stage_progress := int(ceil(float(stage_value + 1) * float(crop_data.days_to_grow) / float(max(1, crop_data.growth_sprites.size()))))
		var waves_until_next = max(0, next_stage_progress - progressed)
		tooltip += ", %d waves until next stage" % waves_until_next

	node.tooltip_text = tooltip

func _apply_growth_stage(stage: int) -> void:
	var sprite_count := crop_data.growth_sprites.size()
	if sprite_count <= 0:
		return

	var clamped_stage = clamp(stage, 0, sprite_count - 1)
	growth_stage = clamped_stage
	sprite.texture = crop_data.growth_sprites[clamped_stage]

	if clamped_stage <= 0:
		harvestable = false
		sell_price = 0
	elif clamped_stage == 1:
		harvestable = true
		sell_price = crop_data.sell_price_initial
	elif clamped_stage == 2:
		harvestable = true
		sell_price = crop_data.sell_price_second
	elif clamped_stage == 3:
		harvestable = true
		sell_price = crop_data.sell_price_third
	else:
		harvestable = true
		sell_price = crop_data.sell_price_final

	days_until_grown = max(0, crop_data.days_to_grow - clamped_stage)
	_update_tooltip()
	
func _on_new_day (_day:int):
	print("Crop ", crop_data)
	if not watered:
		print("Water is important!")
		return
	watered = false
	
	var sprite_count : int = len(crop_data.growth_sprites)
	var growth_percent : float = (crop_data.days_to_grow - days_until_grown) / float(crop_data.days_to_grow)	
	var index : int = floor(growth_percent * sprite_count)
	index = clamp(index, 0, sprite_count - 1)
	_apply_growth_stage(index)
	print_debug("index is: ", index)
	
	if growth_stage == 0:
		print_debug("Seed")
		days_until_grown -= 1
	elif growth_stage == 1:
		print_debug("First Stage")
		days_until_grown -= 1
	elif growth_stage == 2 :
		print_debug("Second Stage")
		days_until_grown -= 1
	elif growth_stage == 3 :
		print_debug("Third Stage")
		days_until_grown -= 1
	else:
		print_debug("Final Stage")
		pass

	_update_tooltip()
		
		
	
	
