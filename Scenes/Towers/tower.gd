class_name Tower extends Node2D

var enemies: Array
# Bullet property defaults (can be overridden per tower instance)
var damage: int
var pierce: int
var reload_speed: float 
var lifetime: float = 1.0
var bullet_speed: int = 1200
var bullet_can_bounce: bool = false
var bullet_bounce_count: int = 0
var dmg_type = "normal"
var twr_range: float
var damage_area: float
var type: Data.Tower
var track_levels: Dictionary = { "damage": 0, "range": 0, "attack_speed": 0 }
var big_upgrade_chosen: String = ""   # "", "A", or "B"
var show_range: bool = false
var is_temp_disabled: bool = false
var disabled_until_time: float = 0.0
var disable_visual_alpha: float = 0.45

@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float, bullet_enum: Data.Bullet, tower_ref: Node)
signal select (tower: Tower)

#func _input(event):
	#if event is InputEventMouseButton and event.button_index == 1 and event.button_mask == 1:
		
	#pass
func _ready():
	init_stats()

func _on_enemy_detection_area_area_entered(area):
	if area not in enemies:
		enemies.append(area)


func _on_enemy_detection_area_area_exited(area):
	if area in enemies:
		enemies.erase(area)


func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.button_mask == 1:
		select.emit(self)
		show_range = true
		queue_redraw()
	
func get_upgrade_data():
	return Data.UPGRADE_DATA[type]
	
#func show_menu():
	#$TowerMenu.setup(self, get_upgrade_data())
	#$TowerMenu.visible = true
	#print("displaying", self)
	
func upgrade_check(): # Used in subclasses for changing stats not included in track, can also be used for sfx later
	pass

func apply_track_upgrade(track : String):
	if track_levels[track] >= Data.UPGRADE_DATA[type]['tracks'][track]['max'] or Data.money < Data.UPGRADE_DATA[type]['tracks'][track]['costs'][track_levels[track]]:
		return
	var increase_amount
	if Data.UPGRADE_DATA[type]['tracks'][track]['type'] == 'percent':
		increase_amount = Data.UPGRADE_DATA[type]['tracks'][track]['base'] * Data.UPGRADE_DATA[type]['tracks'][track]['per_level'] * (track_levels[track] + 1)
	if Data.UPGRADE_DATA[type]['tracks'][track]['type'] == 'flat':
		increase_amount = Data.UPGRADE_DATA[type]['tracks'][track]['per_level']
	match track:
		'damage':
			damage += increase_amount
			print("Damage is ", damage)
		'range':
			twr_range += increase_amount
			$EnemyDetectionArea/CollisionShape2D.shape.radius = twr_range
			queue_redraw()
			print("Range is ", twr_range)
		'attack_speed':
			reload_speed -= (increase_amount * 1)
			print("Attack speed is ", reload_speed)
			$ReloadTimer.wait_time = reload_speed
		'pierce':
			pierce += increase_amount
		'area':
			damage_area += increase_amount
		'bullet_speed':
			bullet_speed += increase_amount
			
	upgrade_check()
	Data.money -= Data.UPGRADE_DATA[type]['tracks'][track]['costs'][track_levels[track]]
	track_levels[track] += 1
	
	

func apply_big_upgrade(key : String):
	pass


func apply_temporary_disable(_duration: float) -> void:
	# TODO: Disable this tower's target/fire behavior for a temporary duration.
	# Suggested behavior: set is_temp_disabled, dim visuals, resume automatically.
	pass


func _update_disable_state() -> void:
	# TODO: Tick and clear temporary disable state.
	pass


func is_disabled() -> bool:
	# TODO: Return true while tower is temporarily disabled.
	return false
	

func _draw():
	if show_range:
		draw_arc(Vector2.ZERO, twr_range, 0, TAU, 64, Color(1, 1, 1, 0.3), 2.0)
		queue_redraw()

func init_stats():
	for track in track_levels:
		match track:
			"range":
				twr_range = Data.UPGRADE_DATA[type]['tracks']['range']['base']
				$EnemyDetectionArea/CollisionShape2D.shape.radius = twr_range
			"attack_speed":
					reload_speed = Data.UPGRADE_DATA[type]['tracks']['attack_speed']['base']
			"damage":
					damage = Data.UPGRADE_DATA[type]['tracks']['damage']['base']
			"area":
					damage_area = Data.UPGRADE_DATA[type]['tracks']['area']['base']
			"pierce":
				pierce = Data.UPGRADE_DATA[type]['tracks']['pierce']['base']
