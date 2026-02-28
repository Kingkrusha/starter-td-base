extends Sprite2D
var parent_tower

func setup(pos, tower_reference):
	position=pos
	parent_tower = tower_reference
	$AnimationPlayer.play("Explosion")
	

func hit_enemies():
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if position.distance_to(enemy.global_position) < parent_tower.damage_area:
			enemy.hit(parent_tower)
