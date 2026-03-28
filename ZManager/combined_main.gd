extends Node2D
signal current_speed(timescale : float, tick_rate : int)

@export var sceneFarm: PackedScene
@export var sceneTower: PackedScene
var farm: Dictionary
var td: Dictionary
var engine_speed: float = 1.0
var tick_speed: int = 60

func _tower_speed(engine : float, tick : int):
	engine_speed = engine
	tick_speed = tick
	
func bind_farm(root_node: Node2D) -> Dictionary:
	return {
		"root": root_node,
		"ui": root_node.get_node("CanvasLayer"),
		"tile": root_node.get_node("FarmManager/FarmTileMap"),
		"camera": root_node.get_node("player/Camera2D")
	}


func bind_tower(root_node: Node2D) -> Dictionary:
	return {
		"root": root_node,
		"ui": root_node.get_node("UI"),
		"tile": null,
		"camera": root_node.get_node("Player Camera")
	}


func apply_view_state(view: Dictionary, is_active: bool):
	var root: Node2D = view["root"]
	var ui: CanvasLayer = view["ui"]
	var tile: CanvasItem = view["tile"]
	var camera: Camera2D = view["camera"]
	root.visible = is_active
	ui.visible = is_active
	if tile : tile.visible = is_active
	camera.enabled = is_active
	root.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED


func _ready():
	farm = bind_farm(sceneFarm.instantiate())
	td = bind_tower(sceneTower.instantiate())
	$scenes.add_child(farm["root"])
	$scenes.add_child(td["root"])
	td["ui"].current_speed.connect(_tower_speed)
	apply_view_state(farm, true)
	apply_view_state(td, false)
	
	
	if not overManager.toggleMode.is_connected(toggle_scenes):
		overManager.toggleMode.connect(toggle_scenes)
	
func toggle_scenes():
	if farm["root"].visible == true:
		apply_view_state(farm, false)
		apply_view_state(td, true)
		Engine.time_scale = engine_speed
		Engine.physics_ticks_per_second = tick_speed
	else:
		apply_view_state(farm, true)
		apply_view_state(td, false)
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = 60
		
	
#func toggle_scenes():
	#farm.visible = ! farm.visible
	#farm_canvas.visible = !farm_canvas.visible
	#farm_tile.visible = !farm_tile.visible
	#farm_camera.enabled = !farm_camera.enabled
	#farm.process_mode = Node.PROCESS_MODE_DISABLED if !scene_farm.visible else Node.PROCESS_MODE_INHERIT
	#
	#td.visible = !td.visible
	#tower_canvas.visible = !tower_canvas.visible
	#tower_tile.visible = !tower_tile.visible
	#tower_camera.enabled = !tower_camera.enabled
	#td.process_mode = Node.PROCESS_MODE_DISABLED if !td.visible else Node.PROCESS_MODE_INHERIT
