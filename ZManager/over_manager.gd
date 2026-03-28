extends Node

signal ChangeFarmMoney (money : int)
signal ChangeTowerMoney (money : int)
signal NewTurn (turn : int)
signal toggleMode()
# Two var to track currency from each aspect of the game (farm and tower)
#var  : int = 0 - to do tower library with unique id's
var plant_money : int = 0
var tower_money : int = 0
var turn : int = 0

func _ready() -> void:
	GameFarmManager.money_changed.connect(_update_farm_money)
	Data.money_changed.connect(_update_tower_money)
	
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
	print(plant_money)
	ChangeFarmMoney.emit(plant_money)
	
func give_money_tower (amount : int):
	tower_money += amount
	Data.money = tower_money
	ChangeTowerMoney.emit(tower_money)
	
func set_new_turn():
	#print("New Turn")
	turn += 1
	NewTurn.emit(turn)
	
	
#Signals to transmit updated currency to each part of the game
#Later implementation of tower to plant tracking via unique id's with dic

#functions to update and then transmit updates to currency.

#List
#Relink money transfers (rewards / ui)
#Add ui button to switch between the main scenes
#Recode and recombine day/wave as the same int to allow for clear progression.
