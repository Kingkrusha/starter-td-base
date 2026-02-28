extends Area2D


var direction: Vector2
var parent_tower: Node = null
var speed: int
var damage: int
var pierce: int
var lifetime: float
var type: String = 'normal'

func setup(pos: Vector2, angle: float, _bullet_enum: Data.Bullet, tower_ref: Node):
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	parent_tower = tower_ref
   # Retrieve bullet properties from the parent tower
	if parent_tower != null:
		damage = parent_tower.damage
		pierce = parent_tower.pierce
		lifetime = parent_tower.lifetime
		speed = parent_tower.bullet_speed
		type = parent_tower.dmg_type
	$Timer.wait_time = lifetime


func _process(delta):
	position += direction * speed * delta


func _on_timer_timeout():
	queue_free()
