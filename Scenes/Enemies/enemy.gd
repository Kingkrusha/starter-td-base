extends Area2D

var speed : int
var health : int
var reward: int
var path_follow : PathFollow2D

func setup(new_path_follow : PathFollow2D, enemy_type: Data.Enemy):
	path_follow = new_path_follow
	var enemy_data = Data.ENEMY_DATA[enemy_type]
	speed = enemy_data['speed']
	health = enemy_data['health']
	reward = round(float(health)/2)
	$Sprite.texture = load(enemy_data['texture'])
	
func _process(delta):
	path_follow.progress += speed * delta
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
	#print("Dealing ", ref.damage, " damage")
	if health <=0 :
		Data.money += reward
		queue_free.call_deferred()

func flash():
	var tween = create_tween()
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 1.0, 0.1)
	tween.tween_property($Sprite.material, 'shader_parameter/progress', 0.0, 0.1)
