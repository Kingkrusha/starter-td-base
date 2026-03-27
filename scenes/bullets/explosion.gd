extends Sprite2D
var parent_tower
var damage_area

func setup(pos, tower_reference):
	global_position = pos
	parent_tower = tower_reference
	if parent_tower != null:
		var scale_value = parent_tower.get("animation_scale")
		if scale_value != null:
			self.scale = Vector2(scale_value, scale_value)
	$AnimationPlayer.play("Explosion")
	

func hit_enemies():
	if parent_tower == null:
		return
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if position.distance_to(enemy.global_position) < (parent_tower.damage_area *6) :
			enemy.hit(parent_tower)
