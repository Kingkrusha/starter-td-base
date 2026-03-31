extends Tower
var animation_scale : float = 6.0

func _ready():
	twr_range = 60
	track_levels = { "damage": 0, "area": 0, "attack_speed": 0 }
	type = Data.Tower.BOMB
	dmg_type = 'explosion'
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
		var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
		shoot.emit($Turret/BulletSpawn.global_position + dir , $Turret.rotation, Data.Bullet.BOMB, self)
		
func apply_big_upgrade(_key : String):
	pass
