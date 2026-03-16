extends Tower


func _ready():
	type = Data.Tower.BLAST
	init_stats()
	twr_range = Data.UPGRADE_DATA[type]['tracks']['range']['base']
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]['tracks']['attack_speed']['base']


func _on_reload_timer_timeout():
	if enemies.size() > 0:
		shoot.emit(position, 0, Data.Bullet.FIRE, self)
		fire_animation()

func fire_animation():
	for particles :GPUParticles2D in $Particles.get_children():
		particles.emitting = true

func apply_big_upgrade(_key : String):
	pass
