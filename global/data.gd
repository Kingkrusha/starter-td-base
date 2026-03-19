extends Node

enum Tower {BASIC, BLAST, MORTAR, SLOW, BOMB}
enum Bullet {SINGLE, FIRE, MORTAR_EXPLOSION, BOMB}
enum Enemy {DEFAULT, FAST, STRONG, BIG, BOSS}
const WAVE_BASE_CREDITS: int = 8
const WAVE_CREDIT_GROWTH: int = 4   
const WAVE_BASE_DELAY: float = 0.7
const WAVE_MIN_DELAY: float = 0.3      
const WAVE_DELAY_REDUCTION: float = 0.002
var HP_MULT_PER_WAVE = 0.02
const ENEMY_UNLOCK_SCHEDULE: Array = [
	[0,  Enemy.DEFAULT],
	[2,  Enemy.FAST],
	[5,  Enemy.STRONG],
	[10, Enemy.BIG],
	[15, Enemy.BOSS],
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
	Enemy.DEFAULT: {'health': 3, 'texture': "res://graphics/Ships/ship_0001.png", 'speed': 170, 'spawn_cost': 1, 'spawn_weight': 5},
	Enemy.FAST: {'health': 3, 'texture': "res://graphics/Ships/ship_0007.png", 'speed': 280, 'spawn_cost': 1, 'spawn_weight': 3},
	Enemy.STRONG: {'health': 6, 'texture': "res://graphics/Ships/ship_0000.png", 'speed': 205, 'spawn_cost': 2, 'spawn_weight': 4},
	Enemy.BIG: {'health': 20, 'texture': "res://graphics/Ships/ship_0005.png", 'speed': 150, 'spawn_cost': 5, 'spawn_weight': 3},
	Enemy.BOSS: {'health': 50, 'texture': "res://graphics/Ships/ship_0015.png", 'speed': 140, 'spawn_cost': 14, 'spawn_weight': 1}}

var health: int = 100:
	set(value):
		health = value
		get_tree().get_first_node_in_group("UI").update_stats(money, health)
var money = 9999:
	set(value):
		money = value
		get_tree().get_first_node_in_group("UI").update_stats(money, health)
		for tower_card in get_tree().get_nodes_in_group('TowerCard'):
			tower_card.toggle_active(money)
