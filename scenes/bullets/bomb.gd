extends Area2D

var direction: Vector2
var parent_tower: Node = null
var speed: int
var damage: int = 0
var pierce: int
var area: int
var lifetime: float
var dmg_type: String = 'explosion'
var explosion_scene = preload("res://scenes/bullets/explosion.tscn")

func setup(pos: Vector2, angle: float, _bullet_enum: Data.Bullet, tower_ref: Node):
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	parent_tower = tower_ref
   # Retrieve bullet properties from the parent tower
	if parent_tower != null:
		pierce = parent_tower.pierce
		lifetime = parent_tower.lifetime
		speed = parent_tower.bullet_speed
		dmg_type = parent_tower.dmg_type
	$Timer.wait_time = lifetime


func _process(delta):
	position += direction * speed * delta


func _on_timer_timeout():
	explode()

func _on_area_entered(area): 
	explode()

func explode():
	var explosion = explosion_scene.instantiate()
	explosion.setup(global_position, parent_tower)
	get_parent().add_child(explosion)
	queue_free.call_deferred()
