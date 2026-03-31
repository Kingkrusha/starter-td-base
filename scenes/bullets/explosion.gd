extends Sprite2D
var parent_tower
var damage_area
var remaining_hits: int = 0

func setup(pos, tower_reference):
	global_position = pos
	parent_tower = tower_reference
	if parent_tower != null:
		# Match projectile pierce behavior: pierce N allows up to N+1 enemy hits.
		remaining_hits = max(0,parent_tower.pierce) + 1
		var scale_value = parent_tower.get("animation_scale")
		if scale_value != null:
			self.scale = Vector2(scale_value, scale_value)
	$AnimationPlayer.play("Explosion")
	

func hit_enemies():
	if parent_tower == null:
		return
	if remaining_hits <= 0:
		return
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if remaining_hits <= 0:
			break
		if position.distance_to(enemy.global_position) < (parent_tower.damage_area *6) :
			enemy.hit(parent_tower)
			remaining_hits -= 1
