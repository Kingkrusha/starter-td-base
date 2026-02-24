extends Area2D

var direction: Vector2
var speed = 200

func setup(pos: Vector2, angle: float, bullet_enum: Data.Bullet):
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle

func _process(delta):
	position += direction * speed * delta
