extends Camera2D

var drag: bool
var acceleration: float = 0.4

func _input(event):
	if event is InputEventMouseButton:
		print(event)
