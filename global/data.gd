extends Node

signal money_changed(new_value : int)
signal health_changed(new_value : int)
enum Tower {BASIC, BLAST, MORTAR, SLOW, BOMB}
enum Bullet {SINGLE, FIRE, MORTAR_EXPLOSION, BOMB}
enum Enemy {
	DEFAULT,
	FAST,
	STRONG,
	BIG,
	BOSS,
	SPECIAL_SHIELD,
	SPECIAL_FULL_HP_BOOST,
	SPECIAL_FIRST_HIT_INVULN,
	SPECIAL_DEATH_SPAWN,
	SPECIAL_FLAT_REDUCTION,
	SPECIAL_DEATH_DISABLE
}
var WAVE_BASE_CREDITS: int = 8
var WAVE_CREDIT_GROWTH: int = 4   
const WAVE_BASE_DELAY: float = 0.7
const WAVE_MIN_DELAY: float = 0.3      
var WAVE_DELAY_REDUCTION: float = 0.02
var SPECIAL_PICK_INTERVAL: int = 5
var SPECIAL_PREP_DELAY: int = 2
const SPECIAL_PICK_START_WAVE: int = 5
var HP_MULT_PER_WAVE = 0.05
const ENEMY_UNLOCK_SCHEDULE: Array = [
	[0,  Enemy.DEFAULT],
	[2,  Enemy.FAST],
	[5,  Enemy.STRONG],
	[10, Enemy.BIG],
	[15, Enemy.BOSS],
]
const SPECIAL_ENEMY_POOL: Array = [
	Enemy.SPECIAL_SHIELD,
	Enemy.SPECIAL_FULL_HP_BOOST,
	Enemy.SPECIAL_FIRST_HIT_INVULN,
	Enemy.SPECIAL_DEATH_SPAWN,
	Enemy.SPECIAL_FLAT_REDUCTION,
	Enemy.SPECIAL_DEATH_DISABLE,
]

func get_scaled_health(enemy : Data.Enemy, wave: int):
	var base_hp: int = ENEMY_DATA[enemy]['health']
	return base_hp * (1 + (HP_MULT_PER_WAVE * wave))

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
		'reload_time': 1.0,
		'bullet': Bullet.SINGLE,
		'thumbnail': "res://graphics/ui/tower thumbnails/basic.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"},
	Tower.BLAST: {
		'name': 'Blaster',
		'cost': 30,
		'reload_time': 1.5,
		'bullet': Bullet.FIRE,
		'thumbnail': "res://graphics/ui/tower thumbnails/blaster.png",
		'portrait': "res://graphics/ui/tower thumbnails/blaster.png"},
	Tower.MORTAR: {
		'name': 'Mortar',
		'cost': 30,
		'reload_time': 2.0,
		'bullet': Bullet.MORTAR_EXPLOSION,
		'thumbnail': "res://graphics/ui/tower thumbnails/mortar.png",
		'portrait': "res://graphics/ui/tower thumbnails/mortar.png"},
	Tower.SLOW: {
		'name': 'Slow',
		'cost': 25,
		'reload_time': 1.2,
		'bullet': Bullet.SINGLE,
		'thumbnail': "res://graphics/towers/basic/basic tower upgrade mockup.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"},
	Tower.BOMB: {
		'name': 'Bomb',
		'cost': 40,
		'reload_time': 1.2,
		'twr_range': 60,
		'bullet': Bullet.SINGLE,
		'thumbnail': "res://graphics/towers/basic/basic tower upgrade mockup.png",
		'portrait': "res://graphics/ui/tower thumbnails/basic.png"}}
var UPGRADE_DATA = {
	Tower.BASIC: {
		"tracks": {
			"damage":       { "base": 1 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"range":        { "base": 70,  "per_level": 10, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.0, "per_level": 0.12, "type": "flat", "max": 5, "costs": [10, 20, 35, 50, 70] },
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
			"attack_speed": { "base": 1.0, "per_level": 0.12, "type": "flat", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Feel the Burn",
				"description": "Applies Burn damage over time effect",
				"cost": 180,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "burn_duration": 3.0, "burn_tick_speed": 0.5, "burn_damage": 1 }
			},
			"B": {
				"name": "flamethrower",
				"description": "increased range and greatly increased attack speed",
				"cost": 175,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "range": 30, "attack_speed_mult": 2.5,}
			}
		}
	},
	Tower.MORTAR: {
		"tracks": {
			"damage":       { "base": 3,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"area":        { "base": 45,  "per_level": 0.10, "type": "percent", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.0, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Feel the Burn",
				"description": "Applies Burn damage over time effect",
				"cost": 180,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "burn_duration": 3.0, "burn_tick_speed": 0.5, "burn_damage": 1 }
			},
			"B": {
				"name": "flamethrower",
				"description": "increased range and greatly increased attack speed",
				"cost": 175,
				"texture": "res://graphics/ui/bigup_normal.png",
				"effects": { "range": 30, "attack_speed_mult": 2.5,}
			}
		}
	},
	Tower.SLOW: {
		"tracks": {
			"damage":       { "base": 0 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [15, 25, 40, 50, 70] },
			"range":        { "base": 70,  "per_level": 10, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.2, "per_level": 0.12, "type": "flat", "max": 5, "costs": [10, 20, 35, 50, 70] },
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
	Tower.BOMB: {
		"tracks": {
			"damage":       { "base": 2 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [15, 25, 40, 50, 70] },
			"area":        { "base": 30,  "per_level": 5, "type": "flat", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.2, "per_level": 0.12, "type": "flat", "max": 5, "costs": [10, 20, 35, 50, 70] },
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
	}
}
const ENEMY_DATA = {
	Enemy.DEFAULT: {
		'health': 3,
		'texture': "res://graphics/ships/ship_0001.png",
		'speed': 170,
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
		'speed': 280,
		'spawn_cost': 1,
		'spawn_weight': 3,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.STRONG: {
		'health': 6,
		'texture': "res://graphics/ships/ship_0000.png",
		'speed': 205,
		'spawn_cost': 2,
		'spawn_weight': 4,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.BIG: {
		'health': 20,
		'texture': "res://graphics/ships/ship_0005.png",
		'speed': 150,
		'spawn_cost': 5,
		'spawn_weight': 3,
		'is_special': false,
		'resistances': {},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.BOSS: {
		'health': 50,
		'texture': "res://graphics/ships/ship_0015.png",
		'speed': 140,
		'spawn_cost': 14,
		'spawn_weight': 1,
		'is_special': false,
		'resistances': {"fire": 0.5},
		'immunities': [],
		'special_id': "none",
		'special_params': {}
	},
	Enemy.SPECIAL_SHIELD: {
		'health': 12,
		'texture': "res://graphics/ships/ship_0011.png",
		'speed': 165,
		'spawn_cost': 8,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "shield_recharge",
		'special_description': "Recharging Shield: Regenerates a protective shield after avoiding damage for a short time.",
		'special_params': {
			'shield_max': 8,
			'recharge_delay': 2.5,
			'recharge_rate': 3.0
		}
	},
	Enemy.SPECIAL_FULL_HP_BOOST: {
		'health': 10,
		'texture': "res://graphics/ships/ship_0012.png",
		'speed': 180,
		'spawn_cost': 8,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {"slow": 0.5},
		'immunities': [],
		'special_id': "full_health_speed_boost",
		'special_description': "Full-Health Boost: Moves much faster while at maximum health.",
		'special_params': {
			'speed_mult_at_full_hp': 1.75
		}
	},
	Enemy.SPECIAL_FIRST_HIT_INVULN: {
		'health': 14,
		'texture': "res://graphics/ships/ship_0013.png",
		'speed': 160,
		'spawn_cost': 9,
		'spawn_weight': 2,
		'is_special': true,
		'resistances': {},
		'immunities': [],
		'special_id': "first_hit_invuln",
		'special_description': "Reactive Barrier: Triggers a brief invulnerability window after its first hit.",
		'special_params': {
			'invuln_duration': 1.25
		}
	},
	Enemy.SPECIAL_DEATH_SPAWN: {
		'health': 16,
		'texture': "res://graphics/ships/ship_0014.png",
		'speed': 150,
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
		'speed': 155,
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
		'health': 15,
		'texture': "res://graphics/ships/ship_0017.png",
		'speed': 150,
		'spawn_cost': 11,
		'spawn_weight': 1,
		'is_special': true,
		'resistances': {"fire": 0.5},
		'immunities': ["slow"],
		'special_id': "death_disable_pulse",
		'special_description': "EMP Pulse: On death, sends out a disabling pulse that temporarily shuts down nearby towers.",
		'special_params': {
			'pulse_radius': 180.0,
			'disable_duration': 2.5
		}
	}
}


var health: int = 100:
	set(value):
		health = value
		health_changed.emit(health)
		#get_tree().get_first_node_in_group("UI").update_stats(money, health)
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
