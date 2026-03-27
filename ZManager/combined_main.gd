extends Node2D

@export var sceneFarm: PackedScene
@export var sceneTower: PackedScene
var farm: Dictionary
var td: Dictionary


func bind_farm(root_node: Node2D) -> Dictionary:
	return {
		"root": root_node,
		"ui": root_node.get_node("CanvasLayer"),
		"tile": root_node.get_node("FarmManager/FarmTileMap"),
		"camera": root_node.get_node("Camera2D")
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
	apply_view_state(farm, true)
	apply_view_state(td, false)
	if not overManager.toggleMode.is_connected(toggle_scenes):
		overManager.toggleMode.connect(toggle_scenes)
	
func toggle_scenes():
	if farm["root"].visible == true:
		apply_view_state(farm, false)
		apply_view_state(td, true)
	else:
		apply_view_state(farm, true)
		apply_view_state(td, false)
	
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
