extends Node

@onready var healthUi : Label = $NinePatchRect/HealthLabel
@onready var waveUi : Label = $NinePatchRect2/WaveLabel
@onready var tower_Money : Label = $NinePatchRect3/TowerMoney
@onready var plant_Money : Label = $NinePatchRect4/PlantMoney

# Called when the node enters the scene tree for the first time.
func _ready():
	_health_ui(Data.health)
	_wave_ui(overManager.turn)
	_tower(overManager.tower_money)
	_plant(overManager.plant_money)
	Data.health_changed.connect(_health_ui)
	overManager.NewTurn.connect(_wave_ui)
	overManager.ChangeTowerMoney.connect(_tower)
	overManager.ChangeFarmMoney.connect(_plant)

func _health_ui(health : int):
	healthUi.text = str(health)

func _wave_ui(wave : int):
	waveUi.text = str(wave)
	
func _tower(money : int):
	tower_Money.text = str(money)

func _plant(money : int):
	plant_Money.text = str(money)
