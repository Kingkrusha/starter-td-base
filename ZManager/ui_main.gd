extends Node

@onready var healthUi : Label = $NinePatchRect/HealthLabel
@onready var waveUi : Label = $NinePatchRect2/WaveLabel
@onready var tower_Money : Label = $NinePatchRect3/TowerMoney
@onready var plant_Money : Label = $NinePatchRect4/PlantMoney

# Called when the node enters the scene tree for the first time.
func _ready():
	_health_ui(Data.health)
	_tower(Data.money)
	_plant(GameFarmManager.money)
	Data.health_changed.connect(_health_ui)
	overManager.NewTurn.connect(_wave_ui)
	GameFarmManager.money_changed.connect(_plant)
	Data.money_changed.connect(_tower)

func _health_ui(health : int):
	print(health)
	healthUi.text = str(health)

func _wave_ui(wave : int):
	waveUi.text = "Wave: " + str(wave)
	
func _tower(money : int):
	#print(money)
	tower_Money.text = str(money)

func _plant(money : int):
	print(money)
	plant_Money.text = str(money)
