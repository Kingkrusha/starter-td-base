extends Tower

func _ready():
	type = Data.Tower.BASIC
	init_stats()
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]["tracks"]["attack_speed"]["base"]

func _process(_delta):
	if enemies.size() > 0:
		$Turret.look_at(enemies[0].global_position)
		$Turret.rotation -= PI/2


func _on_reload_timer_timeout():
	if enemies.size() > 0:
		var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
		shoot.emit(position + dir * 16, $Turret.rotation, Data.Bullet.SINGLE, self)
		
func apply_big_upgrade(_key : String):
	pass
