extends Node

signal money_changed(new_value)

enum Tower {BASIC, BLAST, MORTAR}
enum Bullet {SINGLE, FIRE, MORTAR_EXPLOSION, ICE_EXPLOSION}
enum Enemy {DEFAULT, FAST, STRONG, BIG, BOSS}

const TOWER_DATA = {
	Tower.BASIC: {
		'name': 'Basic',
		'cost': 20,
		'reload_time': 1.0,
		'bullet': Bullet.SINGLE,
		'thumbnail': "res://graphics/ui/tower thumbnails/basic.png",
		'scene': "res://scenes/towers/single_tower.tscn"},
	Tower.BLAST: {
		'name': 'Blaster',
		'cost': 30,
		'reload_time': 1.5,
		'bullet': Bullet.FIRE,
		'thumbnail': "res://graphics/ui/tower thumbnails/blaster.png",
		'scene': "res://scenes/towers/blaster_tower.tscn"},
	Tower.MORTAR: {
		'name': 'Mortar',
		'cost': 30,
		'reload_time': 2.0,
		'bullet': Bullet.MORTAR_EXPLOSION,
		'thumbnail': "res://graphics/ui/tower thumbnails/mortar.png",
		'scene': "res://scenes/towers/mortar_tower.tscn"}}
var UPGRADE_DATA = {
		Tower.BASIC: {
		"tracks": {
			"damage":       { "base": 1 ,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"range":        { "base": 100,  "per_level": 0.10, "type": "percent", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.0, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Fan Shot",
				"description": "Fires 3 bullets in a fan pattern",
				"cost": 150,
				"texture": "res://graphics/ui/tower thumbnails/basic_fan.png",
				"effects": { "bullet_count": 3, "spread_angle": 20.0 }
			},
			"B": {
				"name": "Ricochet",
				"description": "Bullets gain pierce, lifetime, and bounce off walls",
				"cost": 175,
				"texture": "res://graphics/ui/tower thumbnails/basic_ricochet.png",
				"effects": { "pierce": 3, "lifetime_mult": 2.0, "bounce": true }
			}
		}
	},
	Tower.BLAST: {
		"tracks": {
			"damage":       { "base": 1,   "per_level": 1,   "type": "flat",    "max": 5, "costs": [10, 15, 25, 40, 60] },
			"range":        { "base": 35,  "per_level": 0.10, "type": "percent", "max": 5, "costs": [10, 20, 30, 45, 65] },
			"attack_speed": { "base": 1.0, "per_level": 0.12, "type": "percent", "max": 5, "costs": [10, 20, 35, 50, 70] },
		},
		"big": {
			"A": {
				"name": "Feel the Burn",
				"description": "Applies Burn damage over time effect",
				"cost": 180,
				"texture": "res://graphics/ui/tower thumbnails/basic_fan.png",
				"effects": { "burn_duration": 3.0, "burn_tick_speed": 0.5, "burn_damage": 1 }
			},
			"B": {
				"name": "flamethrower",
				"description": "increased range and greatly increased attack speed",
				"cost": 175,
				"texture": "res://graphics/ui/tower thumbnails/basic_ricochet.png",
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
				"texture": "res://graphics/ui/tower thumbnails/basic_fan.png",
				"effects": { "burn_duration": 3.0, "burn_tick_speed": 0.5, "burn_damage": 1 }
			},
			"B": {
				"name": "flamethrower",
				"description": "increased range and greatly increased attack speed",
				"cost": 175,
				"texture": "res://graphics/ui/tower thumbnails/basic_ricochet.png",
				"effects": { "range": 30, "attack_speed_mult": 2.5,}
			}
		}
	}}
const ENEMY_WAVES = {
   0: {
	   "enemies": {Enemy.DEFAULT: 5, Enemy.STRONG: 2, Enemy.FAST: 1},
	   "delay": 0.7
   },
   1: {
	   "enemies": {Enemy.DEFAULT: 5, Enemy.FAST: 1, Enemy.BOSS: 1},
	   "delay": 1.0
   }
}
const ENEMY_DATA = {
	Enemy.DEFAULT: {'health': 3, 'texture': "res://graphics/Ships/ship_0001.png", 'speed': 30},
	Enemy.FAST: {'health': 3, 'texture': "res://graphics/Ships/ship_0007.png", 'speed': 60},
	Enemy.STRONG: {'health': 6, 'texture': "res://graphics/Ships/ship_0000.png", 'speed': 35},
	Enemy.BIG: {'health': 20, 'texture': "res://graphics/Ships/ship_0005.png", 'speed': 25},
	Enemy.BOSS: {'health': 50, 'texture': "res://graphics/Ships/ship_0015.png", 'speed': 20}}


var health: int = 100:
	set(value):
		health = value
		var ui = get_tree().get_first_node_in_group("UI")
		if ui:
			ui.update_stats(money, health)
var money = 100:
	set(value):
		money = value
		money_changed.emit(money)
		var ui = get_tree().get_first_node_in_group("UI")
		print("Money Added")
		if ui:
			print("UI error")
			ui.update_stats(money, health)
			for tower_card in get_tree().get_nodes_in_group('TowerCard'):
				tower_card.toggle_active(money)
