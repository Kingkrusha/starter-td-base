extends Node

signal plant_data(plant : Dictionary)
signal ChangeFarmMoney (money : int)
signal ChangeTowerMoney (money : int)
signal NewTurn (turn : int)
signal toggleMode()


# Two var to track currency from each aspect of the game (farm and tower)
#var  : int = 0 - to do tower library with unique id's

#var tower_inv = Dictionary(String, int)
#var tower_points = Dictionary(String, int)
var plant_money : int = 0
var tower_money : int = 0
var turn : int = 0
var waves : int
func _ready() -> void:
	# Initialize from current values before connecting signals
	tower_money = Data.money
	plant_money = GameFarmManager.money
	
	GameFarmManager.money_changed.connect(_update_farm_money)
	Data.money_changed.connect(_update_tower_money)
	plant_data.connect(determine_towers)
	
func set_waves(setwaves : int):
	waves = setwaves 
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
	#print(plant_money)
	ChangeFarmMoney.emit(plant_money)
	
func give_money_tower (amount : int):
	tower_money += amount
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
