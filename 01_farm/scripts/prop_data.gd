class_name CropData
extends Resource

@export var crop_name: String 
@export var growth_sprites : Array[Texture]
@export var stage_waves_to_next: Array[int] = [1, 2, 3]
@export var stage_sell_prices: Array[int] = []
@export var stage_harvestable: Array[bool] = []
@export var days_to_grow  : int = 8
@export var seed_price : int = 10
@export var sell_price_initial : int = 20
@export var sell_price_second : int  = 40
@export var sell_price_third : int = 30
@export var sell_price_final : int = 0
@export var growth_stage: int = 0
