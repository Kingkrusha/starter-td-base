extends Control

signal wave_num(waves : int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wave_num.connect(overManager.set_waves)


func _on_easy_pressed() -> void:
	wave_num.emit(20)
	get_tree().change_scene_to_file("res://ZManager/combined_scenes/combined_main.tscn")


func _on_normal_pressed() -> void:
	wave_num.emit(40)
	get_tree().change_scene_to_file("res://ZManager/combined_scenes/combined_main.tscn")

func _on_hard_pressed() -> void:
	wave_num.emit(60)
	get_tree().change_scene_to_file("res://ZManager/combined_scenes/combined_main.tscn")
