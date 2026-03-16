extends Tower

var slow: float = 0.7
var slow_duration: float = 3.5


func _ready():
	type = Data.Tower.SLOW
	dmg_type = 'slow'
	init_stats()
	pierce = 1
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]["tracks"]["attack_speed"]["base"]

func _process(_delta):
	if enemies.size() > 0 :
		var targets = get_slowable_targets()
		if targets.size() > 0 :
			$Turret.look_at(targets[0].global_position)
		else :
			$Turret.look_at(enemies[0].global_position)
		$Turret.rotation -= PI/2

func _on_reload_timer_timeout():
	if enemies.size() > 0:
		var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
		shoot.emit(position + dir * 16, $Turret.rotation, Data.Bullet.SINGLE, self)
		
func apply_big_upgrade(_key : String):
	pass

func upgrade_check():
	match damage:
		1:
			slow = 0.6
			slow_duration = 4
		2: 
			slow_duration = 6
		3:
			slow = 0.5
			slow_duration = 8
		4:
			slow = 0.4
			slow_duration = 9
		5:
			slow_duration = 11

func get_slowable_targets():
	var targets = []
	for enemy in enemies:
		if enemy != null and enemy.speed_mult > slow:
			targets.append(enemy)
	for target in targets:
		if target not in enemies:
			targets.erase(target)
	return targets
	
