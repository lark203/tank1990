extends CanvasLayer

# Score 200 overlay, 2 s pause, then next level or victory notification.

var main: Node = null
var level: int = 1

func setup(main_ref: Node, current_level: int) -> void:
	main = main_ref
	level = current_level
	var bg := ColorRect.new()
	bg.size = Vector2(816, 672)
	bg.color = Color.html("#808080")
	add_child(bg)
	var text := Label.new()
	text.text = "Score 200"
	text.position = Vector2(816 / 2.0 - 95, 672 / 2.0 - 22)
	text.add_theme_font_size_override("font_size", 35)
	text.add_theme_color_override("font_color", Color.WHITE)
	add_child(text)

	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
	if level < TankConfig.MAX_LEVEL:
		main.start_next_level(level + 1)
	else:
		var notice := Label.new()
		notice.text = "胜利！！！"
		notice.position = Vector2(816 / 2.0 - 70, 60)
		notice.add_theme_font_size_override("font_size", 35)
		notice.add_theme_color_override("font_color", Color.WHITE)
		add_child(notice)
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(main):
			main.show_menu()
