extends Control

# Approximates FXGL DialogService.showBox("Help", pane, OK) from TankMainMenu.instructions().

func setup() -> void:
	size = Vector2(816, 672)
	var dim := ColorRect.new()
	dim.size = size
	dim.color = Color(0, 0, 0, 0.45)
	add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(188, 186)
	panel.size = Vector2(440, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.html("#F2F2F2")
	style.border_color = Color.html("#B9340D")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var rows := [
		["Movement", "W A S D"],
		["Shoot", "F"],
		["Movement", "UP DOWN LEFT RIGHT"],
		["Shoot", "SPACE"],
	]
	for i in range(rows.size()):
		var label := Label.new()
		label.text = rows[i][0]
		label.position = Vector2(216, 214 + i * 46)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.BLACK)
		add_child(label)
		var keys: Array = rows[i][1].split(" ")
		for j in range(keys.size()):
			var key := Panel.new()
			key.position = Vector2(356 + j * 58, 210 + i * 46)
			key.size = Vector2(50, 36)
			var ks := StyleBoxFlat.new()
			ks.bg_color = Color.WHITE
			ks.border_color = Color.html("#555555")
			ks.set_border_width_all(1)
			key.add_theme_stylebox_override("panel", ks)
			add_child(key)
			var kt := Label.new()
			kt.text = keys[j]
			kt.position = key.position + Vector2(4, 5)
			kt.add_theme_font_size_override("font_size", 15)
			kt.add_theme_color_override("font_color", Color.BLACK)
			add_child(kt)

	var ok := Button.new()
	ok.text = "OK"
	ok.position = Vector2(356, 420)
	ok.custom_minimum_size = Vector2(90, 34)
	ok.pressed.connect(queue_free)
	add_child(ok)
