extends Node

# Top level scene flow: Startup -> MainMenu -> (Construct / Help) -> Game -> Failed / Success.

var level: int = 1
var game: TankGame = null
var menu: Control = null

var _shot_path: String = ""
var _shot_delay: float = 0.0
var _shot_action: String = ""
var _post_delay: float = 4.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.substr(7)
		elif arg.begins_with("--delay="):
			_shot_delay = float(arg.substr(8))
		elif arg.begins_with("--action="):
			_shot_action = arg.substr(9)
		elif arg.begins_with("--post="):
			_post_delay = float(arg.substr(7))
	show_menu()
	if _shot_path != "":
		_auto_shot()

func _auto_shot() -> void:
	await get_tree().create_timer(_shot_delay).timeout
	if menu != null and is_instance_valid(menu):
		if _shot_action == "enter":
			menu.handle_key(_key_event(KEY_ENTER))
			await get_tree().create_timer(2.0).timeout
			if _shot_action == "enter" and OS.get_cmdline_user_args().has("--sim"):
				if game != null and game.player != null:
					# Movement is now polled from Input.is_key_pressed each frame.
					var start_pos: Vector2 = game.player.position
					var ev := InputEventKey.new()
					ev.keycode = KEY_RIGHT
					ev.pressed = true
					Input.parse_input_event(ev)
					await get_tree().create_timer(0.6).timeout
					var ev_up := InputEventKey.new()
					ev_up.keycode = KEY_RIGHT
					ev_up.pressed = false
					Input.parse_input_event(ev_up)
					print("SIM held-right moved=", start_pos, "->", game.player.position,
						" dx=", game.player.position.x - start_pos.x)
					var sp: Sprite2D = game.player.get("sprite")
					print("SIM sprite_centered=", sp.centered, " sprite_pos=", sp.position,
						" rot=", sp.rotation)
					# Enemy bullet hitting an enemy tank must NOT destroy it.
					var en: Node = null
					for e in game.world.entities:
						if e != null and e.entity_type == "ENEMY":
							en = e
							break
					if en != null:
						var b := Bullet.new()
						b.setup(en.position, Vector2(0, -1), 1, "ENEMY")
						game.world.add(b)
						game._resolve_collisions()
						var alive: bool = game.world.entities.has(en)
						print("SIM enemy_alive_after_enemy_bullet=", alive, " expected=true")
			await get_tree().create_timer(maxf(0.0, _post_delay - 2.0)).timeout
		elif _shot_action == "construct":
			menu.handle_key(_key_event(KEY_DOWN))
			menu.handle_key(_key_event(KEY_ENTER))
			await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shot_path)
	get_tree().quit()

func _key_event(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev

func _clear_children() -> void:
	for c in get_children():
		c.queue_free()
	game = null
	menu = null

func show_menu() -> void:
	_clear_children()
	menu = preload("res://src/main_menu.gd").new()
	add_child(menu)
	menu.setup(self)

func start_game_from_menu(requested_level: int = -1) -> void:
	_clear_children()
	# START GAME always plays the original level 1. Only the CONSTRUCT editor's
	# PLAY button passes 0 explicitly to load the user-built custom map.
	level = requested_level if requested_level >= 0 else 1
	game = preload("res://src/game.gd").new()
	add_child(game)
	game.init_game(self, level)

func start_next_level(next_level: int) -> void:
	_clear_children()
	level = next_level
	game = preload("res://src/game.gd").new()
	add_child(game)
	game.init_game(self, level)

func show_help() -> void:
	if menu != null and is_instance_valid(menu):
		menu.show_help()

func show_failed() -> void:
	var scene := preload("res://src/failed_scene.gd").new()
	add_child(scene)
	scene.setup(self)

func show_success() -> void:
	var scene := preload("res://src/success_scene.gd").new()
	add_child(scene)
	scene.setup(self, level)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if game != null and is_instance_valid(game):
			game.handle_key(event)
		if menu != null and is_instance_valid(menu):
			menu.handle_key(event)
