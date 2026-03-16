extends Area2D

var speed : int
var health : int
var reward: int
var path_follow : PathFollow2D
var speed_mult: float = 1.0
var slow_duration: float = 1.0

func setup(new_path_follow : PathFollow2D, enemy_type: Data.Enemy, wave_idx: int = 0):
	path_follow = new_path_follow
	var enemy_data = Data.ENEMY_DATA[enemy_type]
	speed = enemy_data['speed']
	health = Data.get_scaled_health(enemy_type, wave_idx)
	reward = round(float(health)/2)
	$Sprite.texture = load(enemy_data['texture'])
	
func _process(delta):
	path_follow.progress += ((speed * delta) * speed_mult)
	$Sprite.modulate = Color.CADET_BLUE if speed_mult < 1.0 else Color.WHITE
	if path_follow.progress_ratio >= 0.999:
		Data.health -= health
		queue_free()


func _on_area_entered(bullet: Area2D):
	hit(bullet)
	if bullet.pierce > 0:
		bullet.pierce -= 1
	else: 
		bullet.queue_free.call_deferred()
		
func hit(ref):
	flash()
	health -= ref.damage
	if ref.dmg_type == "slow":
		apply_slow(ref.parent_tower.slow, ref.parent_tower.slow_duration)
	#print("Dealing ", ref.damage, " damage")
	if health <=0 :
		Data.money += reward
		queue_free.call_deferred()

func flash():
	var tween = create_tween()
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 1.0, 0.1)
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 0.0, 0.1)

func apply_slow( new_speed: float, duration: float ):
	speed_mult = min(speed_mult, new_speed)
	$SlowTimer.wait_time = duration
	$SlowTimer.start()


func _on_slow_timer_timeout():
	speed_mult = 1.0
