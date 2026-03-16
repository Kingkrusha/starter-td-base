extends Node2D

var range: float = 0.0

func _draw():
	if range > 0:
		draw_arc(Vector2.ZERO, range, 0, TAU, 64, Color(1, 1, 1, 0.3), 2.0)
