extends Tower

var bullet_count: int = 1
var spread_angle_deg: float = 0.0


func _ready():
	type = Data.Tower.BASIC
	init_stats()
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
	if big_upgrade_chosen != "":
		return

	if not Data.UPGRADE_DATA[type]["big"].has(key):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = upgrade["cost"]
	if Data.money < cost:
		return

	var effects: Dictionary = upgrade.get("effects", {})
	match key:
		"A":
			bullet_count = int(effects.get("bullet_count", bullet_count))
			spread_angle_deg = float(effects.get("spread_angle", spread_angle_deg))
		"B":
			pierce += int(effects.get("pierce", 0))
			lifetime *= float(effects.get("lifetime_mult", 1.0))
			bullet_can_bounce = bool(effects.get("bounce", false))
			bullet_bounce_count = int(effects.get("pierce", bullet_bounce_count))

	Data.money -= cost
	big_upgrade_chosen = key
