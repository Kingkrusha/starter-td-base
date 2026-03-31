extends Node

signal plant_data(plant : Dictionary)
signal ChangeFarmMoney (money : int)
signal ChangeTowerMoney (money : int)
signal NewTurn (turn : int)
signal toggleMode()

const MUSIC_F_HEAD: AudioStream = preload("res://01_farm/Audio/F_head.mp3")
const MUSIC_F_BODY: AudioStream = preload("res://01_farm/Audio/F_body.mp3")
const MUSIC_TD_HEAD: AudioStream = preload("res://01_farm/Audio/TD_head.mp3")
const MUSIC_TD_BODY: AudioStream = preload("res://01_farm/Audio/TD_body.mp3")
enum MusicMode { FARM, TD }


# Two var to track currency from each aspect of the game (farm and tower)
#var  : int = 0 - to do tower library with unique id's

#var tower_inv = Dictionary(String, int)
#var tower_points = Dictionary(String, int)
var plant_money : int = 0
var tower_money : int = 0
var turn: int = 0:
	set(value):
		turn = value
		if turn == waves:
			victory()
	
var waves : int
var music_volume_percent: int = 20:
	set(value):
		music_volume_percent = clampi(value, 0, 100)
		_apply_bgm_volume()
var bgm_head_player: AudioStreamPlayer
var bgm_body_player: AudioStreamPlayer
var current_music_mode: int = -1
var pending_body_mode: int = -1
var td_wave_active: bool = false

func _ready() -> void:
	_setup_bgm_players()
	_sync_music_to_wave_state(true)

	# Initialize from current values before connecting signals
	tower_money = Data.money
	plant_money = GameFarmManager.money
	
	GameFarmManager.money_changed.connect(_update_farm_money)
	Data.money_changed.connect(_update_tower_money)
	plant_data.connect(determine_towers)
	Data.defeat.connect(defeat)
func set_waves(setwaves : int):
	waves = setwaves 

func victory():
	get_tree().change_scene_to_file("res://ZManager/combined_scenes/victory.tscn")
func defeat():
	get_tree().change_scene_to_file("res://ZManager/combined_scenes/defeat.tscn")
func set_td_wave_active(is_active: bool) -> void:
	if td_wave_active == is_active:
		return
	td_wave_active = is_active
	_sync_music_to_wave_state()


func _setup_bgm_players() -> void:
	bgm_head_player = AudioStreamPlayer.new()
	bgm_head_player.name = "BGMHeadPlayer"
	bgm_head_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_head_player)

	bgm_body_player = AudioStreamPlayer.new()
	bgm_body_player.name = "BGMBodyPlayer"
	bgm_body_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_body_player)

	if not bgm_head_player.finished.is_connected(_on_bgm_head_finished):
		bgm_head_player.finished.connect(_on_bgm_head_finished)
	if not bgm_body_player.finished.is_connected(_on_bgm_body_finished):
		bgm_body_player.finished.connect(_on_bgm_body_finished)

	_apply_bgm_volume()


func _apply_bgm_volume() -> void:
	var volume_db: float = -80.0 if music_volume_percent <= 0 else linear_to_db(float(music_volume_percent) / 100.0)
	if bgm_head_player != null:
		bgm_head_player.volume_db = volume_db
	if bgm_body_player != null:
		bgm_body_player.volume_db = volume_db


func _music_mode_from_wave_state() -> int:
	return MusicMode.TD if td_wave_active else MusicMode.FARM


func _sync_music_to_wave_state(force: bool = false) -> void:
	var desired_mode := _music_mode_from_wave_state()
	if not force and desired_mode == current_music_mode:
		return
	_start_music_transition(desired_mode)


func _music_head_stream(mode: int) -> AudioStream:
	return MUSIC_TD_HEAD if mode == MusicMode.TD else MUSIC_F_HEAD


func _music_body_stream(mode: int) -> AudioStream:
	return MUSIC_TD_BODY if mode == MusicMode.TD else MUSIC_F_BODY


func _start_music_transition(mode: int) -> void:
	current_music_mode = mode
	pending_body_mode = mode

	if bgm_head_player.playing:
		bgm_head_player.stop()
	if bgm_body_player.playing:
		bgm_body_player.stop()

	bgm_head_player.stream = _music_head_stream(mode)
	bgm_head_player.play()


func _on_bgm_head_finished() -> void:
	if pending_body_mode != current_music_mode:
		return
	bgm_body_player.stream = _music_body_stream(current_music_mode)
	bgm_body_player.play()


func _on_bgm_body_finished() -> void:
	if bgm_body_player.stream != null:
		bgm_body_player.play()

#Money functions might be deprecated. Centralizing currency for a programmer is anethema I suppose.
# wave/day logic will all be controlled via over_manager for simplicity
func _update_tower_money (amount : int):
	tower_money = amount
	ChangeTowerMoney.emit(tower_money)

func _update_farm_money (amount : int):
	#print("Farm money update", amount)
	plant_money = amount
	ChangeFarmMoney.emit(plant_money)

func give_money_farm (amount : int):
	#print("Farm money given ", plant_money)
	plant_money += amount
	Data.record_plant_money_generated(amount)
	#print(plant_money)
	ChangeFarmMoney.emit(plant_money)
	
func give_money_tower (amount : int):
	tower_money += amount
	Data.record_tower_money_generated(amount)
	Data.money = tower_money
	ChangeTowerMoney.emit(tower_money)
	
func set_new_turn():
	#print("New Turn")
	turn += 1
	NewTurn.emit(turn)

func determine_towers(plant_dic : Dictionary) -> Dictionary:
	var tower_allot = {}
	var tower : String
	for crop_name in plant_dic.keys():
		match crop_name:
			"mushroom":
				if plant_dic[crop_name] != null:
					tower = "Basic"
					tower_allot[tower] = plant_dic[crop_name]
				else:
					tower_allot[tower] = 0
			"pepper":
				if plant_dic[crop_name] != null:
					tower = "Blaster"
					tower_allot[tower] = plant_dic[crop_name]
				else:
					tower_allot[tower] = 0
			"pumpkin":
				if plant_dic[crop_name] != null:
					tower = "Mortar"
					tower_allot[tower] = plant_dic[crop_name]
				else:
					tower_allot[tower] = 0
			"blackberry":
				if plant_dic[crop_name] != null:
					tower = "Slow"
					tower_allot[tower] = plant_dic[crop_name]
				else:
					tower_allot[tower] = 0
			"pineapple":
				if plant_dic[crop_name] != null:
					tower = "Bomb"
					tower_allot[tower] = plant_dic[crop_name]
				else:
					tower_allot[tower] = 0
	print(tower_allot)
	return tower_allot
#Signals to transmit updated currency to each part of the game
#Later implementation of tower to plant tracking via unique id's with dic

#functions to update and then transmit updates to currency.
