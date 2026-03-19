extends Control

var tower_ref: Tower  
var track_buttons: Array = []  
signal close()

func setup(tower):
	tower_ref = tower
	var upgrade_data = Data.UPGRADE_DATA[tower.type]
	$"PanelContainer/VBoxContainer/TowerName".text = Data.TOWER_DATA[tower.type]['name']
	$"PanelContainer/VBoxContainer/Tower Preview".texture = load(Data.TOWER_DATA[tower.type]['portrait'])
	
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/Upgrade.text = upgrade_data['big']['A']['name']
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/Upgrade.text = upgrade_data['big']['B']['name']
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/TextureButton.texture_normal = load(upgrade_data['big']['A']['texture'])
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/TextureButton.texture_normal = load(upgrade_data['big']['B']['texture'])
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/TextureButton.tooltip_text = upgrade_data['big']['A']['description']
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/TextureButton.tooltip_text = upgrade_data['big']['B']['description']
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/Cost.text = str(upgrade_data['big']['A']['cost'])
	$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/Cost.text = str(upgrade_data['big']['B']['cost'])
	var rows = [
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/Cost, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/Icon],
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Cost, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Icon],
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/Cost, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/Icon],
	]
	var track_keys = upgrade_data['tracks'].keys()

	for pair in track_buttons:
		if pair[0].is_connected("pressed", _on_track_button_pressed):
			pair[0].disconnect("pressed", _on_track_button_pressed)
	track_buttons.clear()

	for i in range(min(rows.size(), track_keys.size())):
		var btn: TextureButton = rows[i][0]
		var bar: TextureProgressBar = rows[i][1]
		var cost: Label = rows[i][2]
		var icon: TextureRect = rows[i][3]
		var track: String = track_keys[i]
		var track_data = upgrade_data['tracks'][track]

		bar.max_value = track_data['max']
		bar.value = tower.track_levels[track]
		if tower.track_levels[track] < track_data["max"]:
			cost.text = str(track_data['costs'][tower.track_levels[track]])
		else:
			cost.text = "MAX"
		match track:
			"damage":
				icon.texture = load("res://graphics/sol's stuff/Damage Upgrade.png")
				if tower.type == Data.Tower.SLOW:
					icon.get_parent().tooltip_text = "Increase damage and slow potency"
				else:
					icon.get_parent().tooltip_text = "Increase damage"
			"range":
				icon.texture = load("res://graphics/sol's stuff/Range.png")
				if tower.type == Data.Tower.SLOW:
					icon.get_parent().tooltip_text = "Increase range and slow duration"
				else:
					icon.get_parent().tooltip_text = "Increase range"
			"attack_speed":
				icon.texture = load("res://graphics/sol's stuff/speed attempt 2.png")
				icon.get_parent().tooltip_text = "Increase attack speed"
			"area":
				icon.texture = load("res://graphics/sol's stuff/AOE.png")
				icon.get_parent().tooltip_text = "Increase area of effect"

		btn.connect("pressed", _on_track_button_pressed.bind(track))
		track_buttons.append([btn, track])


func _on_track_button_pressed(track: String):
	tower_ref.apply_track_upgrade(track)
	setup(tower_ref)


func _on_exit_button_pressed():
	self.visible = false
	tower_ref.show_range = false
	tower_ref.queue_redraw()
	close.emit()
