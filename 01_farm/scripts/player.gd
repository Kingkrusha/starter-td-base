extends CharacterBody2D

@export var move_speed : float = 45
var facing_direction : Vector2

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
@onready var coll1 : CollisionShape2D = $CollisionShape2D_vertical
@onready var col2 : CollisionShape2D = $CollisionShape2D_side
func _ready():
	facing_direction = Vector2.DOWN
	

func _physics_process(delta):
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if move_input :
		facing_direction = move_input

	velocity = move_input * move_speed
	move_and_slide()
	_animate()

func _animate ():
	var state = "walk" if velocity.length() > 0 else "idle"
	var direction : String
	
	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x > 0:
			direction = "right"
		else:
			direction = "left"
	else:
		if facing_direction.y > 0:
			direction = "down"
		else:
			direction = "up"
			
			
	var anim_name : String = state + "_" + direction
	if (direction == "up" or direction == "down"):
		coll1.disabled = false
		col2.disabled = true
		anim.play(anim_name)
	else:
		coll1.disabled = true
		col2.disabled = false
		if (direction == "right"):
			anim.flip_h = true
			anim.play(anim_name)
		else:
			anim.flip_h = false
			anim.play(anim_name)
