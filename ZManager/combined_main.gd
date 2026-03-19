extends Node2D

@onready var scene_farm = $main
@onready var scene_tower = $Level
@onready var farm_canvas = $main/CanvasLayer      
@onready var tower_canvas = $Level/UI
@onready var farm_tile = $main/FarmManager/FarmTileMap
@onready var tower_tile = $Level/BG/TileMapLayer
@onready var farm_camera = $main/Camera2D
@onready var tower_camera = $Level/PlayerCamera
@onready var farm_crop = $main



func _ready():
	scene_farm.show()
	farm_canvas.visible = true
	farm_tile.show()
	farm_camera.enabled = true
	scene_farm.process_mode = Node.PROCESS_MODE_INHERIT
	
	
	scene_tower.hide()
	tower_canvas.visible = false
	tower_tile.hide()
	tower_camera.enabled = false
	scene_tower.process_mode = Node.PROCESS_MODE_DISABLED
	overManager.toggleMode.connect(toggle_scenes)
	
func toggle_scenes():
	scene_farm.visible = !scene_farm.visible
	farm_canvas.visible = !farm_canvas.visible
	farm_tile.visible = !farm_tile.visible
	farm_camera.enabled = !farm_camera.enabled
	scene_farm.process_mode = Node.PROCESS_MODE_DISABLED if !scene_farm.visible else Node.PROCESS_MODE_INHERIT
	
	scene_tower.visible = !scene_tower.visible
	tower_canvas.visible = !tower_canvas.visible
	tower_tile.visible = !tower_tile.visible
	tower_camera.enabled = !tower_camera.enabled
	scene_tower.process_mode = Node.PROCESS_MODE_DISABLED if !scene_tower.visible else Node.PROCESS_MODE_INHERIT
