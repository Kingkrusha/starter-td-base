extends Tower
var placing_crosshair: bool
var animation_scale : float = 1.0

func _ready():
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
	pass
