extends Camera2D

var drag: bool
@export var max_zoom: float = 4.6
@export var min_zoom: float =0.3
@export var zoom_incriment: float = 0.1
@export var acceleration: float = 0.3

func _input(event):
	if event is InputEventMouseButton and event.button_index == 3 and event.pressed:
		drag = true
	elif event is InputEventMouseButton and event.button_index == 3 and not event.pressed:
		drag = false
	elif event is InputEventMouseButton and event.pressed:
		var current_zoom := zoom.x  # zoom is Vector2; we keep it uniform
		var target := current_zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target = current_zoom - zoom_incriment
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target = current_zoom + zoom_incriment

		target = clamp(target, min_zoom, max_zoom)
		zoom = Vector2(target, target)
	if event is InputEventMouseMotion:
		if drag:
			position -= event.relative * acceleration
