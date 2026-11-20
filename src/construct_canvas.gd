extends Control

# 26x24-cell drawing surface from ui/ConstructPane.java.

var pane: Control = null
var tile_textures: Dictionary = {}

func _draw() -> void:
	draw_rect(Rect2(0, 0, 624, 624), Color.BLACK)
	if pane != null and pane.show_grid:
		for i in range(27):
			var col := Color.html("#ADD8E6") if [5, 10, 16, 21].has(i) else Color.GRAY
			var width := 0.8 if [5, 10, 16, 21].has(i) else 0.5
			draw_line(Vector2(i * 24, 0), Vector2(i * 24, 624), col, width)
			draw_line(Vector2(0, i * 24), Vector2(624, i * 24), col, width)
	if pane != null and pane.map.size() == 26:
		for row in range(26):
			for col in range(26):
				var t: String = pane.map[col][row]
				if t != "EMPTY" and tile_textures.has(t):
					draw_texture(tile_textures[t], Vector2(col * 24, row * 24))

func _gui_input(event: InputEvent) -> void:
	if pane == null:
		return
	if event is InputEventMouseMotion:
		pane.preview_at(event.position)
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			pane.paint(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pane.paint(event.position)

func _mouse_exit() -> void:
	if pane != null:
		pane.hide_preview()
