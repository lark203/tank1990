class_name MapLoader
extends RefCounted

# Reads the original Tiled TMX files, preserving the FXGL TMXLevelLoader rule:
# objects carrying a gid are anchored by their bottom edge in Tiled, so their
# top-left y is (y - height); plain objects (border, sea) keep the raw y.

static func level_path(level_no: int) -> String:
	if level_no == 0:
		return "user://ConstructMap/level0.tmx"
	return "res://assets/levels/level%d.tmx" % level_no

static func load_level(world: TankWorld, level_no: int) -> void:
	var path := level_path(level_no)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("TMX not found: " + path)
		return
	var parser := XMLParser.new()
	if parser.open_buffer(f.get_buffer(f.get_length())) != OK:
		push_warning("TMX parse failed: " + path)
		return
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if parser.get_node_name() != "object":
			continue
		var t := parser.get_named_attribute_value_safe("type")
		if t == "":
			continue
		var x := float(parser.get_named_attribute_value_safe("x"))
		var y := float(parser.get_named_attribute_value_safe("y"))
		var w := float(parser.get_named_attribute_value_safe("width"))
		var h := float(parser.get_named_attribute_value_safe("height"))
		var has_gid := parser.get_named_attribute_value_safe("gid") != ""
		if has_gid:
			y -= h
		make_object(world, t, Vector2(x, y), Vector2(w, h))

static func make_object(world: TankWorld, t: String, pos: Vector2, size: Vector2) -> TankEntity:
	var e := TankEntity.new()
	e.world_ref = world
	e.position = pos
	match t:
		"brick", "stone", "snow":
			var tex: Texture2D = load("res://assets/textures/map/%s.png" % t)
			e.configure(t.to_upper(), Vector2(TankConfig.CELL, TankConfig.CELL), tex)
		"greens":
			e.configure("GREENS", size)
			e.z_index = 100
			var tex: Texture2D = load("res://assets/textures/map/greens.png")
			var cols: int = maxi(1, int(size.x / TankConfig.CELL))
			var rows: int = maxi(1, int(size.y / TankConfig.CELL))
			for r in range(rows):
				for c in range(cols):
					var s := Sprite2D.new()
					s.texture = tex
					s.centered = false
					s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					s.position = Vector2(c * TankConfig.CELL, r * TankConfig.CELL)
					e.add_child(s)
		"sea":
			e.configure("SEA", Vector2(TankConfig.CELL, TankConfig.CELL))
			var frames := SpriteFrames.new()
			frames.remove_animation("default")
			frames.add_animation("play")
			frames.set_animation_speed("play", 2.0)
			var tex: Texture2D = load("res://assets/textures/map/sea_anim.png")
			for i in range(2):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(i * TankConfig.CELL, 0, TankConfig.CELL, TankConfig.CELL)
				frames.add_frame("play", atlas)
			e.anim = AnimatedSprite2D.new()
			e.anim.sprite_frames = frames
			e.anim.centered = false
			e.anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			e.add_child(e.anim)
			e.anim.play("play")
		"border":
			e.configure("BORDER", size)
			var bg := ColorRect.new()
			bg.size = size
			bg.color = Color.html("#D3D3D3")
			e.add_child(bg)
		"flag":
			e.configure("FLAG", Vector2(TankConfig.FLAG_SIZE, TankConfig.FLAG_SIZE), load("res://assets/textures/map/flag.png"))
		_:
			return null
	return world.add(e)
