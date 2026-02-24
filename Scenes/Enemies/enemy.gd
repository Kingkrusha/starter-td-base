extends Area2D

var path_follow : PathFollow2D

func setup(new_path_follow : PathFollow2D):
	path_follow = new_path_follow
	
func _process(delta):
	path_follow.progress += 30 * delta
	#if path_follow.progress >= 0.99:
		#queue_free()


func _on_area_entered(bullet: Area2D):
	bullet.queue_free()
