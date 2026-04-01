extends Node

signal money_changed(new_value : int)
signal health_changed(new_value : int)
signal tower_constraints_changed()
signal defeat()
enum Tower {BASIC, BLAST, MORTAR, SLOW, BOMB}
enum Bullet {SINGLE, FIRE, MORTAR_EXPLOSION, BOMB}
enum Enemy {
	DEFAULT,
	FAST,
	STRONG,
	BIG,
	SPECIAL_BEHEMOTH,
	SPECIAL_SHIELD,
	SPECIAL_PHANTOM,
	SPECIAL_PROTECTOR,
	SPECIAL_ADAPTIVE_DEFENSE,
	SPECIAL_BOOSTER,
	SPECIAL_DEATH_SPAWN,
	SPECIAL_FLAT_REDUCTION,
	SPECIAL_DEATH_DISABLE
}
var WAVE_BASE_CREDITS: int = 4
var WAVE_CREDIT_GROWTH: int = 4   
const WAVE_BASE_DELAY: float = 1.0
const WAVE_MIN_DELAY: float = 0.2      
var WAVE_DELAY_REDUCTION: float = 0.05
var DEBUG_IGNORE_RESOURCES: bool = false
var SPECIAL_PICK_INTERVAL: int = 5
var SPECIAL_PREP_DELAY: int = 2
const SPECIAL_PICK_START_WAVE: int = 5
var HP_MULT_PER_WAVE = 0.07
var BASIC_ENEMY_CREDIT_CAP_RATIO: float = 0.30
const ENEMY_UNLOCK_SCHEDULE: Array = [
	[0,  Enemy.DEFAULT],
	[2,  Enemy.FAST],
	[5,  Enemy.STRONG],
	[10, Enemy.BIG],
]
const SPECIAL_ENEMY_POOL: Array = [
	Enemy.SPECIAL_SHIELD,
	Enemy.SPECIAL_PHANTOM,
	Enemy.SPECIAL_PROTECTOR,
	Enemy.SPECIAL_ADAPTIVE_DEFENSE,
	Enemy.SPECIAL_BOOSTER,
	Enemy.SPECIAL_DEATH_SPAWN,
	Enemy.SPECIAL_FLAT_REDUCTION,
	Enemy.SPECIAL_DEATH_DISABLE,
	Enemy.SPECIAL_BEHEMOTH
]

func _ready() -> void:
	overManager.reset.connect(reset)
func get_scaled_health(enemy : Data.Enemy, wave: int):
	var base_hp: int = ENEMY_DATA[enemy]['health']
	var scaled_health: float = float(base_hp) * (1.0 + (HP_MULT_PER_WAVE * float(wave)))
	if enemy == Enemy.SPECIAL_BEHEMOTH:
		var scaling_multiplier: float = float(ENEMY_DATA[enemy].get("special_params", {}).get("scaling_multiplier", 2.0))
		var extra_scale = 1.0 + (HP_MULT_PER_WAVE * float(wave) * max(0.0, scaling_multiplier - 1.0))
		scaled_health *= extra_scale
	return int(round(scaled_health))

func get_wave_data(wave_idx: int) -> Dictionary:
	var credits = WAVE_BASE_CREDITS + wave_idx * WAVE_CREDIT_GROWTH
	var delay = max(WAVE_BASE_DELAY - wave_idx * WAVE_DELAY_REDUCTION, WAVE_MIN_DELAY)
	var pool: Array = []
	for entry in ENEMY_UNLOCK_SCHEDULE:
		if wave_idx >= entry[0]:
			pool.append(entry[1])
	return { "credits": credits, "pool": pool, "delay": delay }

const TOWER_DATA = {
	Tower.BASIC: {
		'name': 'Basic',
		'cost': 20,
		'reload_time': 1.5,
		'bullet': Bullet.SINGLE,
		'plant_type': 'mushroom',
		'thumbnail': "res://graphics/ui/tower thumbnails/basic.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"},
	Tower.BLAST: {
		'name': 'Blaster',
		'cost': 30,
		'reload_time': 4,
		'bullet': Bullet.FIRE,
		'plant_type': 'pepper',
		'thumbnail': "res://graphics/ui/tower thumbnails/blaster.png",
		'portrait': "res://graphics/ui/tower thumbnails/blaster.png"},
	Tower.MORTAR: {
		'name': 'Mortar',
		'cost': 30,
		'reload_time': 3.2,
		'bullet': Bullet.MORTAR_EXPLOSION,
		'plant_type': 'pineapple',
		'thumbnail': "res://graphics/ui/tower thumbnails/mortar.png",
		'portrait': "res://graphics/ui/tower thumbnails/mortar.png"},
	Tower.SLOW: {
		'name': 'Slow',
		'cost': 25,
		'reload_time': 1.7,
		'bullet': Bullet.SINGLE,
		'plant_type': 'blackberry',
		'thumbnail': "res://graphics/towers/basic/basic tower upgrade mockup.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"},
	Tower.BOMB: {
		'name': 'Bomb',
		'cost': 40,
		'reload_time': 2.2,
		'twr_range': 60,
		'bullet': Bullet.SINGLE,
		'plant_type': 'pumpkin',
		'thumbnail': "res://graphics/towers/basic/basic tower upgrade mockup.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"}}


func notify_tower_constraint_state_changed() -> void:
	tower_constraints_changed.emit()


func get_tower_plant_type(tower_type: Data.Tower) -> String:
	return String(TOWER_DATA.get(tower_type, {}).get("plant_type", ""))


func _collect_tower_nodes() -> Array:
	var towers: Array = []
	for node in get_tree().get_nodes_in_group("Towers"):
		if node is Tower:
			towers.append(node)
	return towers


func _collect_crop_nodes() -> Array:
	var crops: Array = []
	for node in get_tree().get_nodes_in_group("crops"):
		if node is Crop:
			crops.append(node)
	return crops


func get_plant_stage_count(crop_name: String, growth_stage: int) -> int:
	var count := 0
	for crop in _collect_crop_nodes():
		if crop.crop_data == null:
			continue
		var stage_value = crop.get("growth_stage")
		var crop_stage := int(stage_value) if stage_value != null else int(crop.crop_data.growth_stage)
		if String(crop.crop_data.crop_name) == crop_name and crop_stage == growth_stage:
			count += 1
	return count


func get_tower_type_count(tower_type: Data.Tower) -> int:
	var count := 0
	for tower in _collect_tower_nodes():
		if tower.type == tower_type:
			count += 1
	return count


func get_associated_towers_at_or_above_tier(crop_name: String, tier: int) -> int:
	var count := 0
	for tower in _collect_tower_nodes():
		var tower_crop := get_tower_plant_type(tower.type)
		if tower_crop != crop_name:
			continue
		var current_tier: int = max(1, int(tower.get("tower_tier")))
		if current_tier >= tier:
			count += 1
	return count


func is_debug_ignore_resources_enabled() -> bool:
	return DEBUG_IGNORE_RESOURCES


func can_place_tower_from_plants(tower_type: Data.Tower) -> Dictionary:
	if is_debug_ignore_resources_enabled():
		return {"allowed": true, "reason": ""}

	var crop_name := get_tower_plant_type(tower_type)
	if crop_name == "":
		return {"allowed": false, "reason": "No crop mapping configured for this tower."}

	var stage_needed := 1
	var plant_count := get_plant_stage_count(crop_name, stage_needed)
	var existing_towers := get_tower_type_count(tower_type)
	var required := existing_towers + 1
	if plant_count > existing_towers:
		return {
			"allowed": true,
			"reason": "",
			"plant_count": plant_count,
			"required": required,
			"crop_name": crop_name,
			"stage": stage_needed
		}

	return {
		"allowed": false,
		"reason": "Need more %s crops at growth stage %d (%d/%d)." % [crop_name, stage_needed, plant_count, required],
		"plant_count": plant_count,
		"required": required,
		"crop_name": crop_name,
		"stage": stage_needed
	}


func can_upgrade_tower_from_plants(tower: Tower, target_tier: int = -1) -> Dictionary:
	if tower == null:
		return {"allowed": false, "reason": "Tower reference is invalid."}

	var crop_name := get_tower_plant_type(tower.type)
	if crop_name == "":
		return {"allowed": false, "reason": "No crop mapping configured for this tower."}

	if is_debug_ignore_resources_enabled():
		return {
			"allowed": true,
			"reason": "",
			"crop_name": crop_name,
			"tier": target_tier if target_tier > 0 else clamp(int(tower.get("tower_tier")) + 1, 1, 3)
		}

	var current_tier = clamp(int(tower.get("tower_tier")), 1, 3)
	var next_tier = target_tier if target_tier > 0 else current_tier + 1
	next_tier = clamp(next_tier, 1, 3)

	# If this action does not increase effective tier, no additional plant slot is required.
	if next_tier <= current_tier:
		return {
			"allowed": true,
			"reason": "",
			"crop_name": crop_name,
			"tier": next_tier
		}

	var plant_count := get_plant_stage_count(crop_name, next_tier)
	var towers_at_or_above := get_associated_towers_at_or_above_tier(crop_name, next_tier)
	var required := towers_at_or_above + 1
	if plant_count > towers_at_or_above:
		return {
			"allowed": true,
			"reason": "",
			"plant_count": plant_count,
			"required": required,
			"crop_name": crop_name,
			"tier": next_tier
		}

	return {
		"allowed": false,
		"reason": "Need more %s crops at growth stage %d (%d/%d)." % [crop_name, next_tier, plant_count, required],
		"plant_count": plant_count,
		"required": required,
		"crop_name": crop_name,
		"tier": next_tier
	}


func can_harvest_crop_for_towers(crop: Crop) -> Dictionary:
	if crop == null or crop.crop_data == null:
		return {"allowed": false, "reason": "Crop data is invalid."}

	var crop_name := String(crop.crop_data.crop_name)
	var stage_value = crop.get("growth_stage")
	var stage := int(stage_value) if stage_value != null else int(crop.crop_data.growth_stage)
	var before_count = get_plant_stage_count(crop_name, stage)
	var after_count = max(0, before_count - 1)
	var required_towers := get_associated_towers_at_or_above_tier(crop_name, stage)
	if after_count >= required_towers:
		return {
			"allowed": true,
			"reason": "",
			"crop_name": crop_name,
			"stage": stage,
			"after_count": after_count,
			"required": required_towers
		}

	return {
		"allowed": false,
		"reason": "Cannot harvest: %s stage %d would drop to %d, but %d tower(s) require that stage." % [crop_name, stage, after_count, required_towers],
		"crop_name": crop_name,
		"stage": stage,
		"after_count": after_count,
		"required": required_towers
	}
var UPGRADE_DATA = {
	Tower.BASIC: {
		"tracks": {
			"damage":       { "base": 1 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"range":        { "base": 70,  "per_level": 10, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.3, "per_level": 0.15, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Fan Shot",
				"description": "Fires 3 bullets in a fan pattern",
				"cost": 150,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "bullet_count": 3, "spread_angle": 20.0 }
			},
			"B": {
				"name": "Ricochet",
				"description": "Bullets gain pierce, lifetime, and bounce off walls",
				"cost": 175,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "pierce": 3, "lifetime_mult": 2.0, "bounce": true }
			}
		}
	},
	Tower.BLAST: {
		"tracks": {
			"damage":       { "base": 1,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"range":        { "base": 35,  "per_level": 5, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 2.4, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Feel the Burn",
				"description": "Applies Burn damage over time effect",
				"cost": 160,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "burn_duration": 3.0, "burn_tick_speed": 0.5, "burn_damage": 1 }
			},
			"B": {
				"name": "Just Warming Up",
				"description": "During waves, gains +1% range and attack speed per second, up to +150%",
				"cost": 175,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": {
					"tick_interval_seconds": 1.0,
					"gain_percent_per_second": 0.01,
					"max_bonus_percent": 1.5
				}
			}
		}
	},
	Tower.MORTAR: {
		"tracks": {
			"damage":       { "base": 3,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"area":        { "base": 30,  "per_level": 0.10, "type": "percent", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 3.0, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Big Game Buster",
				"description": "Deals more damage the more health the enemy has",
				"cost": 180,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "percentile_damage" : 15.0, "Percentile_damage_cap" : 35 }
			},
			"B": {
				"name": "Concussive Shells",
				"description": "Hit enemies are stunned for a short time",
				"cost": 175,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "stun_duration": 0.8}
			}
		}
	},
	Tower.SLOW: {
		"tracks": {
			"damage":       { "base": 0 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [15, 25, 40, 50, 70] },
			"range":        { "base": 70,  "per_level": 10, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.5, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Impact Gel",
				"description": "Slowed enemies take extra damage",
				"cost": 170,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "bonus_damage": 1 }
			},
			"B": {
				"name": "Glue bomb",
				"description": "Projectiles now explode on impact",
				"cost": 130,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "area":45, "pierce_bonus": 8 }
			}
		}
	},
	Tower.BOMB: {
		"tracks": {
			"damage":       { "base": 2 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [15, 25, 40, 50, 70] },
			"area":        { "base": 30,  "per_level": 5, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 2.0, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Plunder",
				"description": "Killed enemies award extra cash",
				"cost": 180,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "bonus_money" : 2 }
			},
			"B": {
				"name": "Overwhelming offense",
				"description": "Hit enemies temporarally lose damage resistances",
				"cost": 140,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "duration": 8 }
			}
		}
	}
}
var ENEMY_DATA = {
	Enemy.DEFAULT: {
		'health': 4,
		'texture': "res://graphics/ships/ship_0001.png",
		'speed': 190,
		'spawn_cost': 1,
		'spawn_weight': 5,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.FAST: {
		'health': 3,
		'texture': "res://graphics/ships/ship_0007.png",
		'speed': 300,
		'spawn_cost': 1,
		'spawn_weight': 3,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.STRONG: {
		'health': 8,
		'texture': "res://graphics/ships/ship_0000.png",
		'speed': 225,
		'spawn_cost': 2,
		'spawn_weight': 4,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.BIG: {
		'health': 24,
		'texture': "res://graphics/ships/ship_0005.png",
		'speed': 170,
		'spawn_cost': 5,
		'spawn_weight': 3,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.SPECIAL_BEHEMOTH: {
		'health': 55,
		'texture': "res://graphics/ships/ship_0019.png",
		'speed': 170,
		'spawn_cost': 12,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "behemoth",
		'special_description': "Behemoth: Has a LOT of health.",
		'special_params': {
			'scaling_multiplier': 1.5
		}
	},
	Enemy.SPECIAL_SHIELD: {
		'health': 12,
		'texture': "res://graphics/ships/ship_0011.png",
		'speed': 185,
		'spawn_cost': 8,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "shield_recharge",
		'special_description': "Recharging Shield: Regenerates a protective shield after avoiding damage for a short time.",
		'special_params': {
			'shield_max': 9,
			'recharge_delay': 2.5,
			'recharge_rate': 2.0
		}
	},
	Enemy.SPECIAL_PHANTOM: {
		'health': 11,
		'texture': "res://graphics/ships/ship_0012.png",
		'speed': 220,
		'spawn_cost': 8,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {"exlosion": 0.5},
		'immunities': [],
		'special_id': "phantom_phase",
		'special_description': "Phantom: First hit triggers brief invulnerability and a speed surge.",
		'special_params': {
			'invuln_duration': 4.0,
			'speed_mult': 1.6
		}
	},
	Enemy.SPECIAL_PROTECTOR: {
		'health': 16,
		'texture': "res://graphics/ships/ship_0018.png",
		'speed': 175,
		'spawn_cost': 9,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {"slow": 0.5, "fire": 0.5, "explosion": 0.5},
		'immunities': [],
		'special_id': "protector_aura",
		'special_description': "Protector: Shares partial resistance to slow, fire, and explosion with nearby enemies.",
		'special_params': {
			'aura_radius': 55.0,
			'aura_resistance_mult': 0.35,
			'aura_types': ["slow", "fire", "explosion"]
		}
	},
	Enemy.SPECIAL_ADAPTIVE_DEFENSE: {
		'health': 14,
		'texture': "res://graphics/ships/ship_0013.png",
		'speed': 190,
		'spawn_cost': 8,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "adaptive_defense",
		'special_description': "Adaptive Defense: Becomes immune to the first damage type it takes.",
		'special_params': {}
	},
	Enemy.SPECIAL_BOOSTER: {
		'health': 9,
		'texture': "res://graphics/ships/ship_0010.png",
		'speed': 315,
		'spawn_cost': 9,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': ["slow"],
		'special_id': "booster_on_death",
		'special_description': "Booster: On death, grants nearby enemies a temporary speed burst.",
		'special_params': {
			'boost_radius': 150.0,
			'boost_duration': 0.5,
			'boost_mult': 3.0
		}
	},
	Enemy.SPECIAL_DEATH_SPAWN: {
		'health': 18,
		'texture': "res://graphics/ships/ship_0014.png",
		'speed': 180,
		'spawn_cost': 10,
		'spawn_weight': 1,
		'is_special': true,
		'resistances': {"normal": 0.5},
		'immunities': [],
		'special_id': "spawn_on_death",
		'special_description': "Splitting Core: On death, releases smaller enemies onto the path.",
		'special_params': {
			'spawn_enemy_type': Enemy.DEFAULT,
			'spawn_count': 3,
			'spawn_delay': 0.08
		}
	},
	Enemy.SPECIAL_FLAT_REDUCTION: {
		'health': 18,
		'texture': "res://graphics/ships/ship_0016.png",
		'speed': 170,
		'spawn_cost': 10,
		'spawn_weight': 1,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "flat_damage_reduction",
		'special_description': "Armor Plating: Reduces incoming damage by a flat amount each hit.",
		'special_params': {
			'reduce_by': 1,
			'min_damage': 1
		}
	},
	Enemy.SPECIAL_DEATH_DISABLE: {
		'health': 14,
		'texture': "res://graphics/ships/ship_0017.png",
		'speed': 190,
		'spawn_cost': 10,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {"fire": 0.5},
		'immunities': [],
		'special_id': "death_disable_pulse",
		'special_description': "EMP Pulse: On death, sends out a disabling pulse that temporarily shuts down nearby towers.",
		'special_params': {
			'pulse_radius': 300.0,
			'disable_duration': 2.2
		}
	}
}


var stats_enemies_defeated: int = 0
var stats_damage_dealt: int = 0
var stats_tower_money_generated: int = 0
var stats_plant_money_generated: int = 0
var stats_plants_harvested: int = 0
var _stats_tower_damage_by_id: Dictionary = {}


func reset_run_stats() -> void:
	stats_enemies_defeated = 0
	stats_damage_dealt = 0
	stats_tower_money_generated = 0
	stats_plant_money_generated = 0
	stats_plants_harvested = 0
	_stats_tower_damage_by_id.clear()


func record_enemy_defeated(count: int = 1) -> void:
	if count <= 0:
		return
	stats_enemies_defeated += count


func record_damage_dealt(amount: int, tower_ref: Node = null) -> void:
	if amount <= 0:
		return
	stats_damage_dealt += amount
	if tower_ref == null or not (tower_ref is Tower):
		return

	var tower_id := tower_ref.get_instance_id()
	if not _stats_tower_damage_by_id.has(tower_id):
		_stats_tower_damage_by_id[tower_id] = {
			"damage": 0,
			"tower": tower_ref
		}
	_stats_tower_damage_by_id[tower_id]["damage"] += amount


func record_tower_money_generated(amount: int) -> void:
	if amount <= 0:
		return
	stats_tower_money_generated += amount


func record_plant_money_generated(amount: int) -> void:
	if amount <= 0:
		return
	stats_plant_money_generated += amount


func record_plants_harvested(count: int = 1) -> void:
	if count <= 0:
		return
	stats_plants_harvested += count


func get_best_tower_summary() -> String:
	var best_damage := -1
	var best_tower: Tower = null
	for entry in _stats_tower_damage_by_id.values():
		var tower: Tower = entry.get("tower")
		if tower == null or not is_instance_valid(tower):
			continue
		var dealt: int = int(entry.get("damage", 0))
		if dealt > best_damage:
			best_damage = dealt
			best_tower = tower

	if best_tower == null:
		return "None"

	var tower_key: String = Tower.keys()[int(best_tower.type)]
	var track_values: Array = []
	var track_order: Array = ["damage", "range", "area", "attack_speed"]
	for track_name in track_order:
		if UPGRADE_DATA[best_tower.type]["tracks"].has(track_name):
			track_values.append(int(best_tower.track_levels.get(track_name, 0)))
	while track_values.size() < 3:
		track_values.append(0)

	var result := "%s, %d,%d,%d" % [tower_key, track_values[0], track_values[1], track_values[2]]
	if String(best_tower.big_upgrade_chosen) != "":
		var big_key := String(best_tower.big_upgrade_chosen)
		if UPGRADE_DATA[best_tower.type]["big"].has(big_key):
			result += " %s" % String(UPGRADE_DATA[best_tower.type]["big"][big_key].get("name", ""))
	return result


func get_run_stats() -> Dictionary:
	return {
		"enemies_defeated": stats_enemies_defeated,
		"damage_dealt": stats_damage_dealt,
		"tower_money_generated": stats_tower_money_generated,
		"plant_money_generated": stats_plant_money_generated,
		"plants_harvested": stats_plants_harvested,
		"best_tower": get_best_tower_summary()
	}

func reset():
	for tower_card in get_tree().get_nodes_in_group('TowerCard'):
		tower_card.queue_free()
	reset_run_stats()
	health = 100
	money = 500
	

var health: int = 100:
	set(value):
		health = value
		health_changed.emit(health)
		if health < 0:
			health = 0
			defeat.emit()
		
var money = 500:
	set(value):
		money = value
		money_changed.emit(money)
		print("Current tower money: ", money)
		var ui = get_tree().get_first_node_in_group("UI")
		if ui:
			ui.update_stats(money, health)
			for tower_card in get_tree().get_nodes_in_group('TowerCard'):
				tower_card.toggle_active(money)
