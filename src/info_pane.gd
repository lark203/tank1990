class_name InfoPane
extends Control

# Right hand panel: 6 * CELL wide, full app height. Mirrors ui/InfoPane.java,
# restyled per request with real tank sprites and a cleaner layout.

var enemy_icons: Array = []
var bullet_icons: Array = []
var level_label: Label = null

const PANEL_COLOR := Color("#EDEDED")
const ACCENT := Color("#B9350E")

func _init() -> void:
	position = Vector2(TankConfig.FIELD_W, 0)
	size = Vector2(TankConfig.PANEL_W, TankConfig.FIELD_H)
	var bg := ColorRect.new()
	bg.size = size
	bg.color = PANEL_COLOR
	add_child(bg)

	# Decorative accent bars top and bottom.
	var top_bar := ColorRect.new()
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(TankConfig.PANEL_W, 6)
	top_bar.color = ACCENT
	add_child(top_bar)
	var bottom_bar := ColorRect.new()
	bottom_bar.position = Vector2(0, TankConfig.FIELD_H - 6)
	bottom_bar.size = Vector2(TankConfig.PANEL_W, 6)
	bottom_bar.color = ACCENT
	add_child(bottom_bar)

	_add_title("ENEMY", 22)

	# Real tank sprites in a bordered 2x5 grid.
	var grid := ColorRect.new()
	grid.position = Vector2(14, 44)
	grid.size = Vector2(116, 232)
	grid.color = Color(1, 1, 1, 0.55)
	add_child(grid)
	var border := Panel.new()
	border.position = grid.position
	border.size = grid.size
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0)
	bs.border_color = ACCENT
	bs.set_border_width_all(2)
	bs.set_content_margin_all(0)
	border.add_theme_stylebox_override("panel", bs)
	add_child(border)

	var tank_tex: Texture2D = load("res://assets/textures/tank/E1U.png")
	for row in range(5):
		for col in range(2):
			var idx: int = row * 2 + col
			var cell := ColorRect.new()
			cell.position = Vector2(18 + col * 56, 48 + row * 45)
			cell.size = Vector2(52, 42)
			cell.color = Color(0, 0, 0, 0.06)
			add_child(cell)
			var s := Sprite2D.new()
			s.texture = tank_tex
			s.centered = false
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(cell.position.x + 6.0, cell.position.y + 2.0)
			add_child(s)
			enemy_icons.append(s)

	_add_title("STAGE", 288)
	# Stage flag + level number.
	var flag := Sprite2D.new()
	flag.texture = load("res://assets/textures/ui/levelFlag.png")
	flag.centered = false
	flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag.position = Vector2(38, 316)
	add_child(flag)
	level_label = Label.new()
	level_label.text = "1"
	level_label.position = Vector2(38 + 40, 326)
	level_label.add_theme_font_size_override("font_size", 26)
	level_label.add_theme_color_override("font_color", Color.BLACK)
	add_child(level_label)

	_add_title("POWER", 390)
	# Bullet level row: four 29x38 textures, only index 0 visible initially.
	var bullet_tex: Texture2D = load("res://assets/textures/ui/bulletLevel.png")
	for i in range(4):
		var s := Sprite2D.new()
		s.texture = bullet_tex
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2((TankConfig.PANEL_W - 29 * 4) / 2.0 + i * 29, 418)
		s.visible = (i == 0)
		add_child(s)
		bullet_icons.append(s)

func _add_title(text: String, y: float) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(TankConfig.PANEL_W, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", ACCENT)
	add_child(label)

func set_level(n: int) -> void:
	if level_label != null:
		level_label.text = str(n)

func set_enemy_num(n: int) -> void:
	# Java hides from the last icon down to MAX - enemyNum (inclusive).
	var from: int = enemy_icons.size() - 1
	var to: int = TankConfig.MAX_ENEMY - n
	for i in range(from, to - 1, -1):
		if i >= 0 and i < enemy_icons.size():
			enemy_icons[i].visible = false

func set_bullet_level(level: int) -> void:
	# Java listener only ever turns icons on (levels never decrease).
	for i in range(level):
		if i < bullet_icons.size():
			bullet_icons[i].visible = true
