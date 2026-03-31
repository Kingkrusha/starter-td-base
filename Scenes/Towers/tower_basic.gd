extends Tower

var bullet_count: int = 1
var spread_angle_deg: float = 0.0
var big_upgrade_pierce_bonus: int = 0


func _ready():
	type = Data.Tower.BASIC
	init_stats()
	upgrade_check()
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]["tracks"]["attack_speed"]["base"]

func _process(_delta):
	if is_disabled():
		return
	if enemies.size() > 0:
		$Turret.look_at(enemies[0].global_position)
		$Turret.rotation -= PI/2


func _on_reload_timer_timeout():
	if is_disabled():
		return
	if enemies.size() > 0:
		if bullet_count <= 1:
			var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
			shoot.emit($Turret/BulletSpawn.global_position + dir, $Turret.rotation, Data.Bullet.SINGLE, self)
			return

		var total_spread_rad := deg_to_rad(spread_angle_deg)
		for i in range(bullet_count):
			var t := float(i) / float(max(1, bullet_count - 1))
			var offset = lerp(-total_spread_rad * 0.5, total_spread_rad * 0.5, t)
			var shot_angle = $Turret.rotation + offset
			var dir := Vector2.DOWN.rotated(shot_angle).normalized()
			shoot.emit($Turret/BulletSpawn.global_position + dir, shot_angle, Data.Bullet.SINGLE, self)
		
func apply_big_upgrade(key : String):
	var status := can_apply_big_upgrade(key)
	if not bool(status.get("allowed", false)):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = int(status.get("cost", 0))

	var effects: Dictionary = upgrade.get("effects", {})
	match key:
		"A":
			bullet_count = int(effects.get("bullet_count", bullet_count))
			spread_angle_deg = float(effects.get("spread_angle", spread_angle_deg))
		"B":
			big_upgrade_pierce_bonus = int(effects.get("pierce", 0))
			lifetime *= float(effects.get("lifetime_mult", 1.0))
			bullet_can_bounce = bool(effects.get("bounce", false))
			bullet_bounce_count = int(effects.get("pierce", bullet_bounce_count))

	Data.money -= cost
	big_upgrade_chosen = key
	upgrade_check()
	_sync_tower_tier_for_state()
	Data.notify_tower_constraint_state_changed()


func upgrade_check():
	var damage_level := int(track_levels.get("damage", 0))
	pierce = big_upgrade_pierce_bonus

	# Gain +1 pierce at damage levels 1, 3, and 5.
	if damage_level >= 1:
		pierce += 1
	if damage_level >= 3:
		pierce += 1
	if damage_level >= 5:
		pierce += 1
