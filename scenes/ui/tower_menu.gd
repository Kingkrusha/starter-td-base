extends Control

var tower_ref: Tower  
var track_buttons: Array = []  



func setup(tower):
	tower_ref = tower
	var upgrade_data = Data.UPGRADE_DATA[tower.type]
	$"PanelContainer/VBoxContainer/TowerName".text = Data.TOWER_DATA[tower.type]['name']
	$"PanelContainer/VBoxContainer/Tower Preview".texture = load(Data.TOWER_DATA[tower.type]['portrait'])
	
	var rows = [
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/Cost],
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/Cost],
		[$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/TextureButton, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/TextureProgressBar, $PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer3/Cost],
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
		var track: String = track_keys[i]
		var track_data = upgrade_data['tracks'][track]

		bar.max_value = track_data['max']
		bar.value = tower.track_levels[track]
		if tower.track_levels[track] < track_data["max"]:
			cost.text = str(track_data['costs'][tower.track_levels[track]])
		else:
			cost.text = "MAX"

		btn.connect("pressed", _on_track_button_pressed.bind(track))
		track_buttons.append([btn, track])


func _on_track_button_pressed(track: String):
	tower_ref.apply_track_upgrade(track)
	setup(tower_ref)


func _on_exit_button_pressed():
	self.visible = false
