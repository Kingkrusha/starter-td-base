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
var tower_tier: int = 1
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
	_sync_tower_tier_for_state()


func _physics_process(_delta: float) -> void:
	_update_disable_state()
	_update_speed_boost_visual()


func _update_speed_boost_visual() -> void:
	if is_temp_disabled:
		return
	var speed_mult_value = get("speed_mult")
	if speed_mult_value != null and float(speed_mult_value) > 1.0:
		modulate = Color(0.72, 0.5, 1.0, 1.0)
	else:
		modulate = Color.WHITE

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


func _has_any_track_upgrades() -> bool:
	for track in track_levels.keys():
		if int(track_levels[track]) > 0:
			return true
	return false


func _sync_tower_tier_for_state() -> void:
	if big_upgrade_chosen != "":
		tower_tier = 3
	elif _has_any_track_upgrades():
		tower_tier = 2
	else:
		tower_tier = 1


func can_apply_track_upgrade(track: String) -> Dictionary:
	if not Data.UPGRADE_DATA[type]["tracks"].has(track):
		return {"allowed": false, "reason": "Invalid upgrade track."}

	var track_data = Data.UPGRADE_DATA[type]["tracks"][track]
	if track_levels[track] >= track_data["max"]:
		return {"allowed": false, "reason": "Track already at max level."}

	var cost: int = int(track_data["costs"][track_levels[track]])
	if Data.money < cost:
		return {"allowed": false, "reason": "Not enough tower money (%d/%d)." % [Data.money, cost]}

	var gate: Dictionary = Data.can_upgrade_tower_from_plants(self, 2)
	if not bool(gate.get("allowed", false)):
		return {"allowed": false, "reason": String(gate.get("reason", "Plant requirement not met."))}

	return {"allowed": true, "reason": "", "cost": cost}


func can_apply_big_upgrade(key: String) -> Dictionary:
	if big_upgrade_chosen != "":
		return {"allowed": false, "reason": "A big upgrade is already selected."}

	var gate: Dictionary = Data.can_upgrade_tower_from_plants(self, 3)
	if not bool(gate.get("allowed", false)):
		return {"allowed": false, "reason": String(gate.get("reason", "Big upgrades require growth stage 3 plants."))}

	if not Data.UPGRADE_DATA[type]["big"].has(key):
		return {"allowed": false, "reason": "Invalid big upgrade option."}

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = int(upgrade["cost"])
	if Data.money < cost:
		return {"allowed": false, "reason": "Not enough tower money (%d/%d)." % [Data.money, cost]}

	return {"allowed": true, "reason": "", "cost": cost}


func _apply_tier_increase_after_upgrade() -> void:
	_sync_tower_tier_for_state()
	Data.notify_tower_constraint_state_changed()

func apply_track_upgrade(track : String):
	var status := can_apply_track_upgrade(track)
	if not bool(status.get("allowed", false)):
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
	Data.money -= int(status.get("cost", 0))
	track_levels[track] += 1
	_apply_tier_increase_after_upgrade()
	
	

func apply_big_upgrade(key : String):
	pass


func apply_temporary_disable(_duration: float) -> void:
	if _duration <= 0.0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	is_temp_disabled = true
	disabled_until_time = max(disabled_until_time, now + _duration)
	modulate = Color(disable_visual_alpha, disable_visual_alpha, disable_visual_alpha, 1.0)
	if has_node("ReloadTimer"):
		$ReloadTimer.stop()


func _update_disable_state() -> void:
	if not is_temp_disabled:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now >= disabled_until_time:
		is_temp_disabled = false
		disabled_until_time = 0.0
		modulate = Color.WHITE
		if has_node("ReloadTimer") and $ReloadTimer.is_stopped():
			$ReloadTimer.start()


func is_disabled() -> bool:
	return is_temp_disabled
	

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
