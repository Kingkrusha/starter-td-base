extends Area2D

var direction: Vector2
var parent_tower: Node = null
var speed: int
var damage: int
var pierce: int
var lifetime: float
var dmg_type: String = 'normal'
var can_bounce: bool = false
var remaining_bounces: int = 0
var bounce_margin: float = 4.0
var world_left: float = -INF
var world_right: float = INF
var world_top: float = -INF
var world_bottom: float = INF

func setup(pos: Vector2, angle: float, _bullet_enum: Data.Bullet, tower_ref: Node):
	global_position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	parent_tower = tower_ref
	# Retrieve bullet properties from the parent tower
	if parent_tower != null:
		damage = parent_tower.damage
		pierce = parent_tower.pierce
		lifetime = parent_tower.lifetime
		speed = parent_tower.bullet_speed
		dmg_type = parent_tower.dmg_type
		can_bounce = bool(parent_tower.get("bullet_can_bounce"))
		remaining_bounces = int(parent_tower.get("bullet_bounce_count"))
	_cache_world_bounds()
	$Timer.stop()
	$Timer.wait_time = lifetime
	if is_inside_tree():
		$Timer.start()
	else:
		call_deferred("_start_lifetime_timer")


func _start_lifetime_timer():
	if is_inside_tree():
		$Timer.start()


func _process(delta):
	global_position += direction * speed * delta
	if can_bounce and remaining_bounces > 0:
		_bounce_from_world_bounds()


func _cache_world_bounds():
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var world_bounds := current_scene.find_child("WorldBounds", true, false)
	if world_bounds == null:
		return

	var left := world_bounds.get_node_or_null("Left")
	var right := world_bounds.get_node_or_null("Right")
	var top := world_bounds.get_node_or_null("Top")
	var bottom := world_bounds.get_node_or_null("Bottom")
	if left == null or right == null or top == null or bottom == null:
		return

	world_left = left.global_position.x + bounce_margin
	world_right = right.global_position.x - bounce_margin
	world_top = top.global_position.y + bounce_margin
	world_bottom = bottom.global_position.y - bounce_margin


func _bounce_from_world_bounds():
	if world_left == -INF or world_right == INF or world_top == -INF or world_bottom == INF:
		return

	var bounced := false
	if global_position.x < world_left:
		global_position.x = world_left
		direction.x = abs(direction.x)
		bounced = true
	elif global_position.x > world_right:
		global_position.x = world_right
		direction.x = -abs(direction.x)
		bounced = true

	if global_position.y < world_top:
		global_position.y = world_top
		direction.y = abs(direction.y)
		bounced = true
	elif global_position.y > world_bottom:
		global_position.y = world_bottom
		direction.y = -abs(direction.y)
		bounced = true

	if bounced:
		remaining_bounces -= 1
		rotation = direction.angle() + PI / 2


func _on_timer_timeout():
	queue_free()
