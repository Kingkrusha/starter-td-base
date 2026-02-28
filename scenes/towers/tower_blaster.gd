extends Tower


func _ready():
	damage = 1
	type = Data.Tower.BLAST
	$ReloadTimer.wait_time = reload_speed


func _on_reload_timer_timeout():
	if enemies.size() > 0:
		shoot.emit(position, 0, Data.Bullet.FIRE, self)
		fire_animation()

func fire_animation():
	for particles :GPUParticles2D in $Particles.get_children():
		particles.emitting = true
