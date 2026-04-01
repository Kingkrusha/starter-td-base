class_name Crop
extends Node2D

var crop_data : CropData:
	set(value):
		crop_data = value
		_update_tooltip()
var waves_until_next_stage: int = 0
var watered : bool
var harvestable : bool
var tile_map_coords : Vector2i
var sell_price : int
var growth_stage: int = 0
var _last_tooltip_text: String = ""

@onready var sprite : Sprite2D = $Sprite 
@onready var node: Control = $Sprite/Control
func _ready ():
	overManager.NewTurn.connect(_on_new_day)
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.size = Vector2(16, 16)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_tooltip_hitbox()
	_update_tooltip()


func _process(_delta: float) -> void:
	_sync_tooltip_hitbox()
	_update_tooltip()


func _exit_tree() -> void:
	if overManager.NewTurn.is_connected(_on_new_day):
		overManager.NewTurn.disconnect(_on_new_day)


func _sync_tooltip_hitbox() -> void:
	# Keep each tooltip hitbox aligned to its own crop instance in world space.
	node.global_position = global_position + Vector2(-8, -8)
	
func _set_crop (data : CropData, already_watered: bool, tile_coords: Vector2i) :
	crop_data = data
	watered = already_watered
	tile_map_coords = tile_coords
	harvestable = false
	growth_stage = 0
	_apply_growth_stage(0, true)

	# Any crop created before wave/day progression starts gets a free bump to stage 1.
	if overManager.turn == 0 and _stage_count() > 1 and growth_stage < 1:
		set_starting_growth_stage(1)

	_update_tooltip()

func _update_tooltip():
	if crop_data == null:
		if _last_tooltip_text != "":
			node.tooltip_text = ""
			_last_tooltip_text = ""
		return

	var crop_name := String(crop_data.crop_name).capitalize()
	var yield_value := int(sell_price)
	var max_stage = max(0, _stage_count() - 1)
	var stage_value := int(growth_stage)
	var tooltip := "%s, Yield %d, Growth stage %d" % [crop_name, yield_value, stage_value]

	if stage_value < max_stage:
		var waves_until_next := _display_waves_until_next_stage()
		tooltip += ", %d waves until next stage" % waves_until_next
		if not watered:
			tooltip += ", needs water"

	if tooltip != _last_tooltip_text:
		node.tooltip_text = tooltip
		_last_tooltip_text = tooltip


func _display_waves_until_next_stage() -> int:
	if crop_data == null:
		return 0
	var final_stage = max(0, _stage_count() - 1)
	if growth_stage >= final_stage:
		return 0
	if waves_until_next_stage > 0:
		return max(0, waves_until_next_stage)
	return max(0, _stage_waves_to_next(growth_stage))

func _apply_growth_stage(stage: int, reset_stage_timer: bool = true) -> void:
	var stage_count := _stage_count()
	if stage_count <= 0:
		return

	var clamped_stage = clamp(stage, 0, stage_count - 1)
	growth_stage = clamped_stage
	if crop_data.growth_sprites.size() > 0:
		sprite.texture = crop_data.growth_sprites[min(clamped_stage, crop_data.growth_sprites.size() - 1)]
	harvestable = _stage_is_harvestable(clamped_stage)
	sell_price = _stage_sell_price(clamped_stage)
	if reset_stage_timer:
		waves_until_next_stage = _stage_waves_to_next(clamped_stage)

	_update_tooltip()


func _stage_count() -> int:
	if crop_data == null:
		return 0
	var sprite_stages := crop_data.growth_sprites.size()
	var sell_stages := crop_data.stage_sell_prices.size()
	var harvest_stages := crop_data.stage_harvestable.size()
	var wave_stages := crop_data.stage_waves_to_next.size() + 1
	return max(1, max(sprite_stages, max(sell_stages, max(harvest_stages, wave_stages))))


func _stage_waves_to_next(stage: int) -> int:
	var stage_count := _stage_count()
	if stage_count <= 0:
		return 0
	if stage >= stage_count - 1:
		return 0
	match stage:
		0:
			return _stage_wave_or_legacy(0, stage_count)
		1:
			return _stage_wave_or_legacy(1, stage_count)
		2:
			return _stage_wave_or_legacy(2, stage_count)
		3:
			return _stage_wave_or_legacy(3, stage_count)
		4:
			return _stage_wave_or_legacy(4, stage_count)
		_:
			return _stage_wave_or_legacy(stage, stage_count)


func _stage_sell_price(stage: int) -> int:
	if crop_data == null:
		return 0
	match stage:
		0:
			return _stage_sell_or_legacy(0, 0)
		1:
			return _stage_sell_or_legacy(1, crop_data.sell_price_initial)
		2:
			return _stage_sell_or_legacy(2, crop_data.sell_price_second)
		3:
			return _stage_sell_or_legacy(3, crop_data.sell_price_third)
		4:
			return _stage_sell_or_legacy(4, crop_data.sell_price_final)
		_:
			return _stage_sell_or_legacy(stage, crop_data.sell_price_final)


func _stage_is_harvestable(stage: int) -> bool:
	if crop_data == null:
		return false
	match stage:
		0:
			return _stage_harvest_or_legacy(0, false)
		1:
			return _stage_harvest_or_legacy(1, true)
		2:
			return _stage_harvest_or_legacy(2, true)
		3:
			return _stage_harvest_or_legacy(3, true)
		4:
			return _stage_harvest_or_legacy(4, true)
		_:
			return _stage_harvest_or_legacy(stage, stage > 0)


func _stage_wave_or_legacy(stage: int, stage_count: int) -> int:
	if crop_data.stage_waves_to_next.size() > stage:
		return max(0, int(crop_data.stage_waves_to_next[stage]))
	if crop_data.stage_waves_to_next.size() > 0:
		# If only early stage transitions are configured, reuse the last configured value.
		return max(0, int(crop_data.stage_waves_to_next[crop_data.stage_waves_to_next.size() - 1]))
	var transitions = max(1, stage_count - 1)
	return max(1, int(ceil(float(max(1, crop_data.days_to_grow)) / float(transitions))))


func _stage_sell_or_legacy(stage: int, legacy_value: int) -> int:
	if crop_data.stage_sell_prices.size() > stage:
		return int(crop_data.stage_sell_prices[stage])
	return legacy_value


func _stage_harvest_or_legacy(stage: int, legacy_value: bool) -> bool:
	if crop_data.stage_harvestable.size() > stage:
		return bool(crop_data.stage_harvestable[stage])
	return legacy_value


func set_starting_growth_stage(stage: int) -> void:
	if crop_data == null:
		return
	var max_stage = max(0, _stage_count() - 1)
	var clamped_stage = clamp(stage, 0, max_stage)
	_apply_growth_stage(clamped_stage, true)


func set_watered(value: bool) -> void:
	watered = value
	_update_tooltip()
	
func _on_new_day (_day:int):
	print("Crop ", crop_data)
	if not watered:
		print("Water is important!")
		_update_tooltip()
		return
	watered = false

	var final_stage = max(0, _stage_count() - 1)
	if growth_stage >= final_stage:
		_update_tooltip()
		return
	if waves_until_next_stage <= 0:
		waves_until_next_stage = _stage_waves_to_next(growth_stage)

	waves_until_next_stage = max(0, waves_until_next_stage - 1)
	while growth_stage < final_stage and waves_until_next_stage <= 0:
		_apply_growth_stage(growth_stage + 1, true)

	print_debug("stage is: ", growth_stage, " waves_until_next_stage: ", waves_until_next_stage)
		
		
	
	
