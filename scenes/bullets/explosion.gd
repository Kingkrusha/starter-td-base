extends Sprite2D
var parent_tower
var damage_area

func setup(pos, tower_reference):
	global_position = pos
	parent_tower = tower_reference
	self.scale.x = parent_tower.animation_scale
	self.scale.y = parent_tower.animation_scale
	$AnimationPlayer.play("Explosion")
	

func hit_enemies():
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if position.distance_to(enemy.global_position) < (parent_tower.damage_area *6) :
			enemy.hit(parent_tower)
