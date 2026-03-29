extends Tower

var burn_damage: int = 0
var burn_duration: float = 0.0
var burn_tick_speed: float = 0.2

var warmup_enabled: bool = false
var warmup_tick_interval: float = 1.0
var warmup_gain_per_tick: float = 0.05
var warmup_max_bonus_percent: float = 1.5
var warmup_max_range_mult: float = 2.5
var warmup_min_cooldown_mult: float = 0.4
var warmup_tick_accum: float = 0.0
var warmup_range_mult: float = 1.0
var warmup_cooldown_mult: float = 1.0
var warmup_wave_start_range: float = 0.0
var warmup_wave_start_reload: float = 0.0


func _ready():
	type = Data.Tower.BLAST
	init_stats()
	twr_range = Data.UPGRADE_DATA[type]['tracks']['range']['base']
	$ReloadTimer.wait_time = Data.UPGRADE_DATA[type]['tracks']['attack_speed']['base']
	if not overManager.NewTurn.is_connected(_on_new_turn):
		overManager.NewTurn.connect(_on_new_turn)


func _on_reload_timer_timeout():
	if is_disabled():
		return
	if enemies.size() > 0:
		shoot.emit(position, 0, Data.Bullet.FIRE, self)
		fire_animation()


func _process(delta: float) -> void:
	if warmup_enabled and _is_wave_active():
		_update_warmup(delta)

func fire_animation():
	for particles :GPUParticles2D in $Particles.get_children():
		particles.emitting = true


func _is_wave_active() -> bool:
	return get_tree().get_nodes_in_group("enemies").size() > 0


func _on_new_turn(_turn: int) -> void:
	if warmup_enabled:
		_reset_warmup_state()


func _reset_warmup_state() -> void:
	warmup_tick_accum = 0.0
	warmup_range_mult = 1.0
	warmup_cooldown_mult = 1.0
	warmup_wave_start_range = twr_range
	warmup_wave_start_reload = reload_speed
	$EnemyDetectionArea/CollisionShape2D.shape.radius = twr_range
	$ReloadTimer.wait_time = reload_speed


func _update_warmup(delta: float) -> void:
	if warmup_tick_interval <= 0.0:
		return

	warmup_tick_accum += delta
	while warmup_tick_accum >= warmup_tick_interval:
		warmup_tick_accum -= warmup_tick_interval

		if warmup_range_mult >= warmup_max_range_mult and warmup_cooldown_mult <= warmup_min_cooldown_mult:
			break

		warmup_range_mult = min(warmup_range_mult * (1.0 + warmup_gain_per_tick), warmup_max_range_mult)
		warmup_cooldown_mult = max(warmup_cooldown_mult * (1.0 - warmup_gain_per_tick), warmup_min_cooldown_mult)

		twr_range = warmup_wave_start_range * warmup_range_mult
		reload_speed = warmup_wave_start_reload * warmup_cooldown_mult
		$EnemyDetectionArea/CollisionShape2D.shape.radius = twr_range
		$ReloadTimer.wait_time = reload_speed

func apply_big_upgrade(key : String):
	if big_upgrade_chosen != "":
		return

	if not Data.UPGRADE_DATA[type]["big"].has(key):
		return

	var upgrade = Data.UPGRADE_DATA[type]["big"][key]
	var cost: int = upgrade["cost"]
	if Data.money < cost:
		return

	var effects: Dictionary = upgrade.get("effects", {})
	match key:
		"A":  # Feel the Burn
			burn_damage = int(effects.get("burn_damage", 0))
			burn_duration = float(effects.get("burn_duration", 0.0))
			burn_tick_speed = float(effects.get("burn_tick_speed", 0.2))
			dmg_type = "burn"
		"B":  # Just Warming Up
			warmup_enabled = true
			warmup_tick_interval = float(effects.get("tick_interval_seconds", 1.0))
			warmup_gain_per_tick = float(effects.get("gain_percent_per_second", 0.05))
			warmup_max_bonus_percent = float(effects.get("max_bonus_percent", 1.5))
			warmup_max_range_mult = 1.0 + warmup_max_bonus_percent
			warmup_min_cooldown_mult = 1.0 / max(1.0 + warmup_max_bonus_percent, 0.001)
			_reset_warmup_state()

	Data.money -= cost
	big_upgrade_chosen = key
