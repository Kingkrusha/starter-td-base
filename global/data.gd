extends Node

enum Tower {BASIC, BLAST, MORTAR}
enum Bullet {SINGLE, FIRE, MORTAR_EXPLOSION, ICE_EXPLOSION}
enum Enemy {DEFAULT, FAST, STRONG, BIG}

const TOWER_DATA = {
	Tower.BASIC: {
		'name': 'Basic',
		'cost': 20,
		'upgrade_cost': 30,
		'reload_time': 1.0,
		'bullet': Bullet.SINGLE,
		'thumbnail': "res://graphics/ui/tower thumbnails/basic.png",
		'scene': "res://scenes/towers/single_tower.tscn"},
	Tower.BLAST: {
		'name': 'Blaster',
		'cost': 30,
		'upgrade_cost': 50,
		'reload_time': 1.5,
		'bullet': Bullet.FIRE,
		'thumbnail': "res://graphics/ui/tower thumbnails/blaster.png",
		'scene': "res://scenes/towers/blaster_tower.tscn"},
	Tower.MORTAR: {
		'name': 'Mortar',
		'cost': 30,
		'upgrade_cost': 60,
		'reload_time': 2.0,
		'bullet': Bullet.MORTAR_EXPLOSION,
		'thumbnail': "res://graphics/ui/tower thumbnails/mortar.png",
		'scene': "res://scenes/towers/mortar_tower.tscn"}}
const UPGRADE_DATA = {
	Tower.BASIC: {
		'reload_time': 0.6,
		'bullet': Bullet.SINGLE},
	Tower.BLAST: {
		'reload_time': 1.2,
		'bullet': Bullet.FIRE},
	Tower.MORTAR: {
		'reload_time': 1.5,
		'bullet': Bullet.ICE_EXPLOSION}}
const ENEMY_WAVES = {
	0: {Enemy.DEFAULT: 5, Enemy.STRONG: 2, Enemy.FAST: 1},
	1: {Enemy.DEFAULT: 5, Enemy.FAST: 1}}
const ENEMY_DATA = {
	Enemy.DEFAULT: {'health': 3, 'texture': "res://graphics/Ships/ship_0004.png", 'speed': 20},
	Enemy.FAST: {'health': 3, 'texture': "res://graphics/Ships/ship_0007.png", 'speed': 50},
	Enemy.STRONG: {'health': 6, 'texture': "res://graphics/Ships/ship_0000.png", 'speed': 25},
	Enemy.BIG: {'health': 20, 'texture': "res://graphics/Ships/ship_0015.png", 'speed': 15}}
