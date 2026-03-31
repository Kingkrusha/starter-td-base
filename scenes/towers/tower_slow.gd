extends Tower

var slow: float = 0.7
var slow_duration: float = 3.5
var sedative_bonus_damage: int = 0
var use_glue_bomb: bool = false
var animation_scale: float = 4.0


func _ready():
	type = Data.Tower.SLOW
	dmg_type = 'slow'
	init_stats()
	pierce = 1
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]["tracks"]["attack_speed"]["base"]

func _process(_delta):
	if is_disabled():
		return
	if enemies.size() > 0 :
		var targets = get_slowable_targets()
		if targets.size() > 0 :
			$Turret.look_at(targets[0].global_position)
		else :
			$Turret.look_at(enemies[0].global_position)
		$Turret.rotation -= PI/2

func _on_reload_timer_timeout():
	if is_disabled():
		return
	if enemies.size() > 0:
		var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
		var bullet_type: Data.Bullet = Data.Bullet.BOMB if use_glue_bomb else Data.Bullet.SINGLE
		shoot.emit(position + dir * 16, $Turret.rotation, bullet_type, self)
		
func apply_big_upgrade(key : String):
	var status := can_apply_big_upgrade(key)
	if not bool(status.get("allowed", false)):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = int(status.get("cost", 0))
	var effects: Dictionary = upgrade.get("effects", {})

	match key:
		"A":
			sedative_bonus_damage = int(effects.get("bonus_damage", 1))
		"B":
			use_glue_bomb = true
			damage_area = effects.get("area", damage_area)
			pierce += effects.get("pierce_bonus")
			animation_scale = max(1.0, damage_area / 6.0)

	Data.money -= cost
	big_upgrade_chosen = key
	_sync_tower_tier_for_state()
	Data.notify_tower_constraint_state_changed()

func upgrade_check():
	var damage_level := int(track_levels.get("damage", 0))
	var range_level := int(track_levels.get("range", 0))

	# Slow potency scales off damage track levels.
	if damage_level >= 4:
		slow = 0.4
	elif damage_level >= 2:
		slow = 0.5
	elif damage_level >= 1:
		slow = 0.6
	else:
		slow = 0.7

	# Slow duration scales off range track levels.
	match range_level:
		0:
			slow_duration = 3.5
		1:
			slow_duration = 4.0
		2:
			slow_duration = 6.0
		3:
			slow_duration = 8.0
		4:
			slow_duration = 9.0
		_:
			slow_duration = 11.0

func get_slowable_targets():
	var targets = []
	for enemy in enemies:
		if enemy != null and enemy.speed_mult > slow:
			targets.append(enemy)
	for target in targets:
		if target not in enemies:
			targets.erase(target)
	return targets
	
