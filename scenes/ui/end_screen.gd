extends Control

var run_stats: Dictionary = {}
@onready var stats_container: VBoxContainer = $PanelContainer/VBoxContainer/StatsContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	fetch_end_game_stats()
	apply_stats_to_labels()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func fetch_end_game_stats() -> Dictionary:
	run_stats = Data.get_run_stats()
	return run_stats


func apply_stats_to_labels() -> void:
	if run_stats.is_empty():
		fetch_end_game_stats()
	if stats_container == null:
		return

	for child in stats_container.get_children():
		child.queue_free()

	var entries := [
		{"name": "Enemies Defeated", "value": str(run_stats.get("enemies_defeated", 0))},
		{"name": "Damage Dealt", "value": str(run_stats.get("damage_dealt", 0))},
		{"name": "Tower Money Generated", "value": str(run_stats.get("tower_money_generated", 0))},
		{"name": "Plant Money Generated", "value": str(run_stats.get("plant_money_generated", 0))},
		{"name": "Plants Harvested", "value": str(run_stats.get("plants_harvested", 0))},
		{"name": "Best Tower", "value": str(run_stats.get("best_tower", "None"))}
	]

	for entry in entries:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = "%s: %s" % [entry["name"], entry["value"]]
		stats_container.add_child(label)
