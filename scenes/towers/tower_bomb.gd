extends Tower
var animation_scale : float = 6.0
var resistance_strip_duration: float = 0.0

func _ready():
	twr_range = 60
	track_levels = { "damage": 0, "area": 0, "attack_speed": 0 }
	type = Data.Tower.BOMB
	dmg_type = 'explosion'
	init_stats()
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]["tracks"]["attack_speed"]["base"]

func _process(_delta):
	if is_disabled():
		return
	if enemies.size() > 0:
		$Turret.look_at(enemies[0].global_position)
		$Turret.rotation -= PI/2


func _on_reload_timer_timeout():
	if is_disabled():
		return
	if enemies.size() > 0:
		var dir = Vector2.DOWN.rotated($Turret.rotation).normalized()
		shoot.emit($Turret/BulletSpawn.global_position + dir , $Turret.rotation, Data.Bullet.BOMB, self)
		
func apply_big_upgrade(key : String):
	var status := can_apply_big_upgrade(key)
	if not bool(status.get("allowed", false)):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = int(status.get("cost", 0))
	var effects: Dictionary = upgrade.get("effects", {})

	match key:
		"A":
			extra_money = int(effects.get("bonus_money", 0))
		"B":
			resistance_strip_duration = effects.get("duration", 0.0)

	Data.money -= cost
	big_upgrade_chosen = key
	_sync_tower_tier_for_state()
	Data.notify_tower_constraint_state_changed()
