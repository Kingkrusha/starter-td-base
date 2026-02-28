class_name Tower extends Node2D

var enemies: Array
# Bullet property defaults (can be overridden per tower instance)
var damage: int = 1
var pierce: int = 0
var reload_speed: float = 1.0
var lifetime: float = 1.0
var bullet_speed: int = 200
var dmg_type = "normal"
var damage_area: float
var type: Data.Tower
@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float, bullet_enum: Data.Bullet, tower_ref: Node)
signal select (tower: Tower)

func _on_enemy_detection_area_area_entered(area):
	if area not in enemies:
		enemies.append(area)



func _on_enemy_detection_area_area_exited(area):
	if area in enemies:
		enemies.erase(area)


func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.button_mask == 1:
		select.emit(self)
