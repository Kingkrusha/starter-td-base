@abstract
class_name Tower extends Node2D

var enemies: Array
# Bullet property defaults (can be overridden per tower instance)
var damage: int = 1
var pierce: int = 0
var reload_speed: float = 1.0
var lifetime: float = 1.0
var bullet_speed: int = 200
var dmg_type = "normal"
var range: float = 100
var damage_area: float
var type: Data.Tower
var track_levels: Dictionary = { "damage": 0, "range": 0, "attack_speed": 0 }
var big_upgrade_chosen: String = ""   # "", "A", or "B"

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
		
func get_upgrade_data():
	return Data.UPGRADE_DATA[type]

func apply_track_upgrade(track : String):
	if track_levels[track] >= Data.UPGRADE_DATA[type]['tracks'][track]['max'] or Data.money < Data.UPGRADE_DATA[type]['tracks'][track]['costs'][track_levels[track]]:
		return
	var increase_amount
	if Data.UPGRADE_DATA[type]['tracks'][track]['type'] == 'percent':
		increase_amount = Data.UPGRADE_DATA[type]['tracks'][track]['base'] * Data.UPGRADE_DATA[type]['tracks'][track]['per_level'] * (track_levels[track] + 1)
	if Data.UPGRADE_DATA[type]['tracks'][track]['type'] == 'flat':
		increase_amount = Data.UPGRADE_DATA[type]['tracks'][track]['per_level'] * (track_levels[track] +1)
	match track:
		'damage':
			damage += increase_amount
		'range':
			range += increase_amount
		'attack_speed':
			reload_speed -= increase_amount
		'pierce':
			pierce += increase_amount
		'area':
			damage_area += increase_amount
		'bullet_speed':
			bullet_speed += increase_amount
			
	track_levels[track] += 1

@abstract func apply_big_upgrade(key : String)
