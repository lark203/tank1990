extends Control

# 1:1 port of ui/ConstructPane.java: 26x26 editor, 12 brushes, TMX export.

var main: Node = null
var map: Array = []
var brush: String = "BRICK"
var is_big: bool = false
var show_grid: bool = false
var selected_brush: int = 0
var canvas: Control = null
var preview: Sprite2D = null
var brush_buttons: Array = []

const BRUSHES := [
	["BRICK", false], ["BRICK", true],
	["STONE", false], ["STONE", true],
	["SNOW", false], ["SNOW", true],
	["SEA", false], ["SEA", true],
	["GREENS", false], ["GREENS", true],
	["EMPTY", false], ["EMPTY", true],
]

func setup(main_ref: Node) -> void:
	main = main_ref
	size = Vector2(816, 672)
	var bg := ColorRect.new()
	bg.size = size
	bg.color = Color.html("#808080")
	add_child(bg)

	canvas = preload("res://src/construct_canvas.gd").new()
	canvas.pane = self
	canvas.position = Vector2(24, 24)
	canvas.size = Vector2(624, 624)
	for t in ["BRICK", "STONE", "SNOW", "SEA", "GREENS"]:
		canvas.tile_textures[t] = load("res://assets/textures/map/%s.png" % t.to_lower())
	add_child(canvas)
	canvas.mouse_exited.connect(hide_preview)

	var flag := Sprite2D.new()
	flag.texture = load("res://assets/textures/map/flag.png")
	flag.centered = false
	flag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flag.position = canvas.position + Vector2(288, 576)
	add_child(flag)

	preview = Sprite2D.new()
	preview.centered = false
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate.a = 0.8
	preview.position = Vector2(-100, -100)
	add_child(preview)

	var panel := ColorRect.new()
	panel.position = Vector2(672, 0)
	panel.size = Vector2(144, 672)
	panel.color = Color.WHITE
	add_child(panel)

	for i in range(BRUSHES.size()):
		var entry: Array = BRUSHES[i]
		var tex: Texture2D = load("res://assets/textures/map/%s%s.png" % [entry[0].to_lower(), "4" if entry[1] else ""])
		var btn := Button.new()
		btn.icon = tex
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(46, 46) if i % 2 == 0 else Vector2(64, 64)
		btn.position = Vector2(680 if i % 2 == 0 else 744, 60 + (i / 2) * 60)
		_style_button(btn, Color.WHITE)
		btn.pressed.connect(_select_brush.bind(i))
		add_child(btn)
		brush_buttons.append(btn)
	_select_brush(0)

	var grid := CheckBox.new()
	grid.text = "Show Grid"
	_style_button(grid, Color.WHITE)
	grid.add_theme_color_override("font_color", Color.BLACK)
	grid.position = Vector2(680, 450)
	grid.custom_minimum_size = Vector2(130, 30)
	grid.toggled.connect(func(on: bool) -> void:
		show_grid = on
		canvas.queue_redraw()
	)
	add_child(grid)

	_add_button("Back to Menu", Vector2(680, 495), _back_to_menu)
	_add_button("Clear Tiles", Vector2(680, 540), _clear_tiles)
	_add_button("Reload Map", Vector2(680, 585), _reload_map)
	_add_button("Start Game", Vector2(680, 630), _start_game, true)

	init_map_data()

func _style_button(btn: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = color
		btn.add_theme_stylebox_override(state, st)

func _add_button(text: String, pos: Vector2, action: Callable, red: bool = false) -> void:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.custom_minimum_size = Vector2(130, 30)
	_style_button(btn, Color.WHITE)
	btn.add_theme_color_override("font_color", Color.html("#E53737") if red else Color.BLACK)
	btn.pressed.connect(action)
	add_child(btn)

func _select_brush(index: int) -> void:
	selected_brush = index
	var entry: Array = BRUSHES[index]
	brush = entry[0]
	is_big = entry[1]
	for i in range(brush_buttons.size()):
		_style_button(brush_buttons[i] as Button, Color.BLACK if i == index else Color.WHITE)
	preview.texture = load("res://assets/textures/map/%s%s.png" % [brush.to_lower(), "4" if is_big else ""])

func init_map_data() -> void:
	DirAccess.make_dir_recursive_absolute("user://ConstructMap")
	var f := FileAccess.open("user://ConstructMap/level0.data", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Array and parsed.size() == 26:
			map = parsed
			canvas.queue_redraw()
			return
	reset_map()

func reset_map() -> void:
	map = []
	for col in range(26):
		var row_array: Array = []
		for row in range(26):
			row_array.append("EMPTY")
		map.append(row_array)
	for c in [11, 12, 13, 14]:
		map[c][23] = "BRICK"
	map[11][24] = "BRICK"
	map[11][25] = "BRICK"
	map[14][24] = "BRICK"
	map[14][25] = "BRICK"

func preview_at(pos: Vector2) -> void:
	var col: int = int(pos.x / 24)
	var row: int = int(pos.y / 24)
	if col < 0 or row < 0 or col > 25 or row > 25:
		hide_preview()
		return
	preview.visible = true
	preview.position = canvas.position + Vector2(col * 24, row * 24)

func hide_preview() -> void:
	if preview != null:
		preview.position = Vector2(-100, -100)

func paint(pos: Vector2) -> void:
	var col: int = int(pos.x / 24)
	var row: int = int(pos.y / 24)
	if col < 0 or row < 0 or col > 25 or row > 25:
		return
	_apply(col, row)
	if is_big:
		if col + 1 <= 25:
			_apply(col + 1, row)
		if row + 1 <= 25:
			_apply(col, row + 1)
		if col + 1 <= 25 and row + 1 <= 25:
			_apply(col + 1, row + 1)
	canvas.queue_redraw()

func _apply(col: int, row: int) -> void:
	if col >= 12 and col <= 13 and row >= 24:
		return
	map[col][row] = brush

func _back_to_menu() -> void:
	save_map(false)
	main.show_menu()

func _clear_tiles() -> void:
	reset_map()
	canvas.queue_redraw()

func _reload_map() -> void:
	init_map_data()
	canvas.queue_redraw()

func _start_game() -> void:
	save_map(true)

func save_map(start_game: bool) -> void:
	var lines: Array = [
		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
		"<map version=\"1.8\" tiledversion=\"1.8.4\" orientation=\"orthogonal\" renderorder=\"right-down\" width=\"28\" height=\"28\" tilewidth=\"24\" tileheight=\"24\" infinite=\"0\" nextlayerid=\"3\" nextobjectid=\"361\">",
		" <tileset firstgid=\"1\" name=\"maptitles\" tilewidth=\"24\" tileheight=\"24\" tilecount=\"9\" columns=\"9\">",
		"  <image source=\"maptitles.png\" width=\"216\" height=\"24\"/>",
		" </tileset>",
		" <tileset firstgid=\"10\" name=\"flag\" tilewidth=\"48\" tileheight=\"48\" tilecount=\"1\" columns=\"1\">",
		"  <image source=\"flag.png\" width=\"48\" height=\"48\"/>",
		" </tileset>",
		" <objectgroup id=\"2\" name=\"objLayout\">",
		"  <object id=\"95\" type=\"flag\" gid=\"10\" x=\"312\" y=\"648\" width=\"48\" height=\"48\"/>",
		"  <object id=\"96\" type=\"border\" x=\"0\" y=\"0\" width=\"672\" height=\"24\"/>",
		"  <object id=\"97\" type=\"border\" x=\"648\" y=\"24\" width=\"24\" height=\"648\"/>",
		"  <object id=\"98\" type=\"border\" x=\"0\" y=\"648\" width=\"648\" height=\"24\"/>",
		"  <object id=\"99\" type=\"border\" x=\"0\" y=\"24\" width=\"24\" height=\"624\"/>",
	]
	var id: int = 100
	var gids := {"BRICK": 1, "SNOW": 3, "STONE": 4, "GREENS": 5}
	for row in range(26):
		for col in range(26):
			var t: String = map[col][row]
			if t == "EMPTY":
				continue
			var y: int = (row + 2) * 24
			var gid_str: String = ""
			if t == "SEA":
				y = (row + 1) * 24
			elif gids.has(t):
				gid_str = " gid=\"%d\"" % gids[t]
			lines.append("  <object id=\"%d\" type=\"%s\"%s x=\"%d\" y=\"%d\" width=\"24\" height=\"24\"/>" % [id, t.to_lower(), gid_str, (col + 1) * 24, y])
			id += 1
	lines.append(" </objectgroup>")
	lines.append("</map>")

	DirAccess.make_dir_recursive_absolute("user://ConstructMap")
	var tmx := FileAccess.open("user://ConstructMap/level0.tmx", FileAccess.WRITE)
	if tmx != null:
		tmx.store_string("\n".join(lines))
		tmx.close()
	var data := FileAccess.open("user://ConstructMap/level0.data", FileAccess.WRITE)
	if data != null:
		data.store_string(JSON.stringify(map))
		data.close()
	if start_game:
		main.start_game_from_menu(0)
