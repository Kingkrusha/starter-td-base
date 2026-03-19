extends CanvasLayer

var tool_buttons : Array[ToolButton]

@onready var money_text : Label = $MoneyText
@onready var day_text : Label = $DayText

func _ready():
	for child in $ToolButtons.get_children():
		if child is ToolButton:
			tool_buttons.append(child)
	GameFarmManager.SetPlayerTool.connect(_on_set_player_tool)
	overManager.ChangeFarmMoney.connect(_on_change_money)
	overManager.NewTurn.connect(_on_new_day)
func _on_set_player_tool (tool : PlayerTools.Tool, seed : CropData):
	for button in tool_buttons:
		if button.tool != tool or button.seed != seed:
			button.self_modulate = Color.WHITE
		else:
			button.self_modulate = Color.GREEN

func _on_change_money (money : int):
	money_text.text = "$" + str(money)

func _on_new_day (day : int):
	day_text.text = "Day " + str(day)


func _on_next_day_button_pressed() -> void:
	overManager.toggleMode.emit()
