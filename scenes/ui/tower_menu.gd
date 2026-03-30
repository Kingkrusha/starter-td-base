extends Control

var tower_ref: Tower  
var track_buttons: Array = []  
var big_buttons: Array = []
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
	var big_btn_a: TextureButton = $PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/TextureButton
	var big_btn_b: TextureButton = $PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/TextureButton

	for pair in big_buttons:
		var btn: TextureButton = pair[0]
		var cb: Callable = pair[1]
		if btn.is_connected("pressed", cb):
			btn.disconnect("pressed", cb)
	big_buttons.clear()

	var big_a_cb := _on_big_upgrade_pressed.bind("A")
	var big_b_cb := _on_big_upgrade_pressed.bind("B")
	big_btn_a.connect("pressed", big_a_cb)
	big_btn_b.connect("pressed", big_b_cb)
	big_buttons.append([big_btn_a, big_a_cb])
	big_buttons.append([big_btn_b, big_b_cb])

	var selected_big : String = tower.big_upgrade_chosen
	var big_a_status: Dictionary = tower_ref.can_apply_big_upgrade("A")
	var big_b_status: Dictionary = tower_ref.can_apply_big_upgrade("B")
	big_btn_a.disabled = not bool(big_a_status.get("allowed", false))
	big_btn_b.disabled = not bool(big_b_status.get("allowed", false))
	var big_a_desc := String(upgrade_data['big']['A']['description'])
	var big_b_desc := String(upgrade_data['big']['B']['description'])
	if big_btn_a.disabled:
		big_btn_a.tooltip_text = "%s\n%s" % [big_a_desc, String(big_a_status.get("reason", "Unavailable."))]
	else:
		big_btn_a.tooltip_text = big_a_desc
	if big_btn_b.disabled:
		big_btn_b.tooltip_text = "%s\n%s" % [big_b_desc, String(big_b_status.get("reason", "Unavailable."))]
	else:
		big_btn_b.tooltip_text = big_b_desc

	if selected_big == "A":
		$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/Cost.text = "OWNED"
		$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/Cost.text = "LOCKED"
	elif selected_big == "B":
		$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer/Cost.text = "LOCKED"
		$PanelContainer/VBoxContainer/FlowContainer/VBoxContainer2/Cost.text = "OWNED"

	for pair in track_buttons:
		var btn: TextureButton = pair[0]
		var cb: Callable = pair[1]
		if btn.is_connected("pressed", cb):
			btn.disconnect("pressed", cb)
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
		var track_status: Dictionary = tower_ref.can_apply_track_upgrade(track)
		btn.disabled = not bool(track_status.get("allowed", false))
		btn.tooltip_text = String(track_status.get("reason", "Upgrade available.")) if btn.disabled else ""
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

		var cb := _on_track_button_pressed.bind(track)
		btn.connect("pressed", cb)
		track_buttons.append([btn, cb])


func _on_track_button_pressed(track: String):
	tower_ref.apply_track_upgrade(track)
	setup(tower_ref)


func _on_big_upgrade_pressed(key: String):
	tower_ref.apply_big_upgrade(key)
	setup(tower_ref)


func _on_texture_button_pressed():
	# Legacy signal connection from the scene file
	pass


func _on_exit_button_pressed():
	self.visible = false
	if tower_ref:
		tower_ref.show_range = false
		tower_ref.queue_redraw()
	close.emit()


func _on_remove_button_pressed():
	tower_ref.queue_free()
