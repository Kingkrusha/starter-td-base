class_name PlayerTools

extends Node2D

enum Tool 
{
	HOE,
	WATER_BUCKET,
	SCYTHE,
	SEED
}

var current_tool : Tool
var current_seed : CropData = preload("res://01_farm/crops/mushroom.tres")

@onready var farm_manager : FarmManager = $"../../FarmManager"


func _ready ():
	GameFarmManager.SetPlayerTool.connect(_set_tool)
	GameFarmManager.SetPlayerTool.emit.call_deferred(Tool.HOE, null)


func _set_tool (tool : Tool, seed : CropData):
	current_tool = tool
	current_seed = seed

func _process(delta):
	if Input.is_action_just_pressed("interact"):
		match current_tool:
			Tool.HOE:
				farm_manager.try_till_tile(global_position)
			Tool.WATER_BUCKET:
				farm_manager.try_water_tile(global_position)
			Tool.SCYTHE:
				farm_manager.try_harvest_tile(global_position)
			Tool.SEED:
				farm_manager.try_seed_tile(global_position, current_seed)
