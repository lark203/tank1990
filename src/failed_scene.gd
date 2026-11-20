extends CanvasLayer

# GameOver.png slides up from the bottom with FXGL ELASTIC.EASE_OUT (2.6 s).

var main: Node = null

func setup(main_ref: Node) -> void:
	main = main_ref
	var tex := TextureRect.new()
	tex.texture = load("res://assets/textures/ui/GameOver.png")
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex.position = Vector2(28 * 24 / 2.0 - tex.texture.get_width() / 2.0, 672)
	add_child(tex)
	var tween := create_tween()
	tween.tween_property(tex, "position:y", 260.0, 2.6)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if main != null and is_instance_valid(main):
			main.show_menu()
	)
