extends Control

# 1:1 port of ui/TankMainMenu.java and ui/MainMenuButton.java.

var main: Node = null
var buttons: Array = []
var selected: int = 0
var tank_icon: Sprite2D = null

const LABELS := ["START GAME", "CONSTRUCT", "HELP", "EXIT"]

func setup(main_ref: Node) -> void:
	main = main_ref
	size = Vector2(816, 672)
	var bg := ColorRect.new()
	bg.size = size
	bg.color = Color.BLACK
	add_child(bg)

	var logo := Sprite2D.new()
	logo.texture = load("res://assets/textures/ui/logo.png")
	logo.centered = false
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.position = Vector2(144, 160)
	add_child(logo)

	tank_icon = Sprite2D.new()
	tank_icon.texture = load("res://assets/textures/ui/tankLoading.png")
	tank_icon.centered = false
	tank_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tank_icon.position = Vector2(172, 252)
	add_child(tank_icon)

	for i in range(LABELS.size()):
		var btn := Button.new()
		btn.text = LABELS[i]
		# Centre the icon+label block (bbox x=245..448 -> centre 346.5) in the
		# 816-wide canvas (centre 408): shift the whole VBox right by 60px.
		btn.position = Vector2(300, 360 + i * 45)
		btn.custom_minimum_size = Vector2(320, 40)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		# JavaFX RadioButton: 39px graphic + 30px graphicTextGap -> text starts at 69.
		style.content_margin_left = 69
		style.content_margin_top = 6
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 23)
		# Button uses state-specific font colours: overriding only "font_color"
		# leaves hover white (default theme) until the mouse leaves. Set all four.
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_color_override("font_focus_color", Color.WHITE)
		# Godot Button consumes arrow keys for focus navigation by default, which
		# double-fires our own handler (one key press -> two menu steps).
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_entered.connect(_on_hover.bind(i))
		btn.pressed.connect(_activate.bind(i))
		add_child(btn)
		var icon := Sprite2D.new()
		icon.texture = load("res://assets/textures/ui/icon.png")
		# JavaFX rotates the graphic about its centre. With centered=false Godot
		# rotates about the top-left corner, throwing the icon up/left of the row.
		icon.centered = true
		icon.rotation = deg_to_rad(180)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Centre of the 39px graphic in the 40px-tall button row, left of text (x=69).
		icon.position = Vector2(25, 20)
		icon.visible = (i == 0)
		btn.add_child(icon)
		buttons.append({"button": btn, "icon": icon})

	var line := ColorRect.new()
	line.position = Vector2(30, 580)
	line.size = Vector2(740, 2)
	line.color = Color.html("#B9340D")
	add_child(line)
	var fxgl := Sprite2D.new()
	fxgl.texture = load("res://assets/textures/ui/fxgl.png")
	fxgl.centered = false
	fxgl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fxgl.position = Vector2(310, 600)
	add_child(fxgl)

	_select(0)
	TankSound.play("mainMenuLoad.wav", self)
	# buttons appear only after the tank reaches its destination
	for item in buttons:
		(item["button"] as Button).visible = false
	# Fast entrance then a small left/right wobble with elastic settle.
	var tween := create_tween()
	tween.tween_property(tank_icon, "position:x", 374.0, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tank_icon, "position:x", 354.0, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tank_icon, "position:x", 388.0, 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tank_icon, "position:x", 374.0, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		for item in buttons:
			(item["button"] as Button).visible = true
	)

func _on_hover(index: int) -> void:
	if selected != index:
		TankSound.play("mainMenuHover.wav", self)
	_select(index)

func _select(index: int) -> void:
	selected = index
	for i in range(buttons.size()):
		var item: Dictionary = buttons[i]
		var btn := item["button"] as Button
		var c := Color.html("#B9350E") if i == index else Color.WHITE
		btn.add_theme_color_override("font_color", c)
		btn.add_theme_color_override("font_hover_color", c)
		btn.add_theme_color_override("font_pressed_color", c)
		btn.add_theme_color_override("font_focus_color", c)
		(item["icon"] as Sprite2D).visible = (i == index)

func _activate(index: int) -> void:
	TankSound.play("select.wav", self)
	match index:
		0:
			main.start_game_from_menu()
		1:
			var pane := preload("res://src/construct_pane.gd").new()
			add_child(pane)
			pane.setup(main)
			for c in get_children():
				if c != pane and c is CanvasItem:
					c.hide()
		2:
			show_help()
		3:
			get_tree().quit()

func handle_key(event: InputEventKey) -> void:
	# A physical key press emits both press and release events. Without this guard
	# one arrow key press steps the menu twice.
	if event.echo or not event.pressed:
		return
	if event.keycode == KEY_DOWN or event.keycode == KEY_UP:
		var delta: int = 1 if event.keycode == KEY_DOWN else -1
		TankSound.play("mainMenuHover.wav", self)
		_select((selected + delta + buttons.size()) % buttons.size())
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		_activate(selected)

func show_help() -> void:
	var dlg := preload("res://src/help_dialog.gd").new()
	add_child(dlg)
	dlg.setup()
