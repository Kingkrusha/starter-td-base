extends Tower
var placing_crosshair: bool
var animation_scale : float = 1.0
var mortar_percentile_damage: float = 0.0
var mortar_percentile_damage_cap: int = 0
var stun_duration: float = 0.0

func _ready():
	pierce = 6
	track_levels = { "damage": 0, "area": 0, "attack_speed": 0 }
	dmg_type = 'explosion'
	animation_scale = 6
	type = Data.Tower.MORTAR
	init_stats()
	$ReloadTimer.wait_time = reload_speed


func show_crosshair():
	$CrosshairSprite.show()
	placing_crosshair = true
func crosshair_pos_update(pos: Vector2i):
	$CrosshairSprite.global_position = pos

func finish_placing():
	$CrosshairSprite.hide()
	placing_crosshair = false
func _on_reload_timer_timeout():
	if is_disabled():
		return
	if not placing_crosshair:
		shoot.emit($CrosshairSprite.global_position,0,Data.Bullet.MORTAR_EXPLOSION, self)

func apply_big_upgrade(key : String):
	var status := can_apply_big_upgrade(key)
	if not bool(status.get("allowed", false)):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = int(status.get("cost", 0))
	var effects: Dictionary = upgrade.get("effects", {})

	match key:
		"A":
			mortar_percentile_damage = effects.get("percentile_damage", 0.0)
			mortar_percentile_damage_cap = int(effects.get("Percentile_damage_cap", effects.get("percentile_damage_cap", 0)))
		"B":
			stun_duration = effects.get("stun_duration", 0.0)

	Data.money -= cost
	big_upgrade_chosen = key
	_sync_tower_tier_for_state()
	Data.notify_tower_constraint_state_changed()
