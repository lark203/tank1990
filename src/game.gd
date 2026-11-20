class_name TankGame
extends Node2D

# 1:1 port of com.leo.TankApp + all collision handlers.
# No Godot physics is used: FXGL's per-frame AABB collision order is emulated explicitly.

var main: Node = null
var world: TankWorld = null
var info: InfoPane = null

var level: int = 1
var enemy_num: int = 3
var destroyed: int = 0
var freeze_enemy: bool = false
var player: Tank = null
var state: String = "idle"

var spawn_accum: float = 0.0
var item_spawn_accum: float = 0.0
var freeze_left: float = 0.0
var spade_left: float = 0.0
var win_left: float = -1.0

var transition: CanvasLayer = null
var curtain_top: ColorRect = null
var curtain_bottom: ColorRect = null
var stage_text: Label = null

func init_game(main_ref: Node, level_no: int) -> void:
	main = main_ref
	level = level_no
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(TankConfig.FIELD_W, TankConfig.FIELD_H)
	bg.color = Color.BLACK
	add_child(bg)
	world = TankWorld.new()
	add_child(world)
	info = InfoPane.new()
	add_child(info)
	build_and_start_level()

func build_and_start_level() -> void:
	state = "intro"
	for e in world.by_types(["BULLET", "ENEMY", "PLAYER"]):
		world.remove(e)
	_build_transition()
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(_on_intro_done)

func _build_transition() -> void:
	transition = CanvasLayer.new()
	add_child(transition)
	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(TankConfig.FIELD_W, TankConfig.FIELD_H / 2.0)
	top.color = Color.html("#333333")
	transition.add_child(top)
	var bottom := ColorRect.new()
	bottom.position = Vector2(0, TankConfig.FIELD_H / 2.0)
	bottom.size = Vector2(TankConfig.FIELD_W, TankConfig.FIELD_H / 2.0)
	bottom.color = Color.html("#333333")
	transition.add_child(bottom)
	var text := Label.new()
	text.text = "STAGE " + str(level)
	text.position = Vector2(TankConfig.FIELD_W / 2.0 - 80, TankConfig.FIELD_H / 2.0 - 5)
	text.add_theme_font_size_override("font_size", 35)
	text.add_theme_color_override("font_color", Color.WHITE)
	transition.add_child(text)
	curtain_top = top
	curtain_bottom = bottom
	stage_text = text

func _on_intro_done() -> void:
	stage_text.visible = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(curtain_top, "position:y", -TankConfig.FIELD_H / 2.0, 1.2)
	tween.tween_property(curtain_bottom, "position:y", TankConfig.FIELD_H, 1.2)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(transition):
			transition.queue_free()
			transition = null
	)
	start_level()

func start_level() -> void:
	freeze_left = 0.0
	spade_left = 0.0
	win_left = -1.0
	freeze_enemy = false
	enemy_num = TankConfig.INIT_ENEMY
	destroyed = 0
	spawn_accum = 0.0
	item_spawn_accum = 0.0
	world.clear()
	MapLoader.load_level(world, level)
	TankSound.play("start.wav", self)

	player = Tank.new()
	player.world_ref = world
	player.setup(true, world, self, load("res://assets/textures/tank/H1U.png"))
	player.position = Vector2(100, 600)
	world.add(player)
	info.set_level(level)
	info.set_enemy_num(enemy_num)

	for p in TankConfig.spawn_points():
		spawn_enemy(p)
	state = "playing"

func _pick_enemy_kind() -> String:
	var total: int = 0
	for k in TankConfig.ENEMY_TYPES.keys():
		total += int((TankConfig.ENEMY_TYPES[k] as Dictionary)["weight"])
	var roll: int = randi() % total
	for k in TankConfig.ENEMY_TYPES.keys():
		roll -= int((TankConfig.ENEMY_TYPES[k] as Dictionary)["weight"])
		if roll < 0:
			return k
	return "NORMAL"

func spawn_enemy(pos: Vector2) -> void:
	var kind := _pick_enemy_kind()
	var cfg: Dictionary = TankConfig.ENEMY_TYPES[kind]
	var names: Array = cfg["textures"]
	var tex: Texture2D = load("res://assets/textures/tank/" + names[randi() % names.size()])
	var e := Tank.new()
	e.world_ref = world
	e.setup(false, world, self, tex, kind)
	e.position = pos
	world.add(e)

func spawn_bullet(pos: Vector2, dir: Vector2, lvl: int, owner: String) -> void:
	TankSound.play("normalFire.wav", self)
	var b := Bullet.new()
	b.world_ref = world
	b.setup(pos, dir, lvl, owner)
	world.add(b)

func spawn_explode(pos: Vector2, full: bool) -> void:
	TankSound.play("normalBomb.wav" if full else "rocketBomb.wav", self)
	var e := Explosion.new()
	e.world_ref = world
	e.setup(pos, full)
	world.add(e)

func spawn_item(pos: Vector2) -> void:
	var kinds := ["STAR", "GUN", "TANK", "HEART", "BOMB", "SHIP", "HELMET", "TIME", "SPADE"]
	var kind: String = kinds[randi() % kinds.size()]
	_spawn_item_kind(pos, kind)

func _spawn_item_kind(pos: Vector2, kind: String) -> void:
	var item := Item.new()
	item.world_ref = world
	item.setup(pos, kind)
	world.add(item)

# Pick an open 24px grid cell: no terrain/tank/item and not on the base or
# the player spawn. Guarantees map-wide random drops never appear inside walls.
func _find_open_cell() -> Vector2:
	var solid := ["BORDER", "BRICK", "STONE", "SEA", "GREENS", "FLAG", "PLAYER", "ENEMY", "ITEM"]
	for _try in range(60):
		var c: int = randi_range(2, 25)
		var r: int = randi_range(2, 25)
		var p := Vector2(c * TankConfig.CELL, r * TankConfig.CELL)
		# keep clear of the base (bottom centre) and player spawn corner
		if p.x >= 240.0 and p.x <= 384.0 and p.y >= 552.0:
			continue
		if p.x <= 144.0 and p.y >= 552.0:
			continue
		var occupied := false
		for e in world.in_rect(Rect2(p, Vector2(TankConfig.CELL, TankConfig.CELL))):
			if solid.has(e.entity_type):
				occupied = true
				break
		if not occupied:
			return p
	return Vector2(-1, -1)

func _try_spawn_random_item() -> void:
	if world.by_type("ITEM").size() >= TankConfig.ITEM_MAX_ON_FIELD:
		return
	var p := _find_open_cell()
	if p.x < 0.0:
		return
	_spawn_item_kind(p, ["STAR", "GUN", "TANK", "HEART", "BOMB", "SHIP", "HELMET", "TIME", "SPADE"][randi() % 9])

func _process(delta: float) -> void:
	if state != "playing":
		return
	for e in world.entities.duplicate():
		if is_instance_valid(e) and e is Tank:
			e.tick(delta)
	# Held-key polling: FXGL's Input checks key state every frame, so the player
	# keeps moving while a direction key is held (not just on key-down events).
	if player != null and is_instance_valid(player) and player.freeze_left <= 0.0:
		if Input.is_key_pressed(KEY_UP):
			player.try_move(TankConfig.DIR_UP)
		elif Input.is_key_pressed(KEY_DOWN):
			player.try_move(TankConfig.DIR_DOWN)
		elif Input.is_key_pressed(KEY_LEFT):
			player.try_move(TankConfig.DIR_LEFT)
		elif Input.is_key_pressed(KEY_RIGHT):
			player.try_move(TankConfig.DIR_RIGHT)
	for e in world.entities.duplicate():
		if is_instance_valid(e) and e is Tank and not e.is_player:
			e.enemy_update(delta)
	for e in world.entities.duplicate():
		if is_instance_valid(e) and e is Bullet:
			e.step(delta)
	_resolve_collisions()
	for e in world.entities.duplicate():
		if not is_instance_valid(e):
			continue
		if e is Item:
			e.tick(delta)
		elif e is Explosion:
			e.tick(delta)

	spawn_accum += delta
	if spawn_accum >= TankConfig.SPAWN_INTERVAL:
		spawn_accum -= TankConfig.SPAWN_INTERVAL
		_try_spawn_enemy()

	item_spawn_accum += delta
	if item_spawn_accum >= TankConfig.ITEM_SPAWN_INTERVAL:
		item_spawn_accum -= TankConfig.ITEM_SPAWN_INTERVAL
		_try_spawn_random_item()

	if freeze_left > 0.0:
		freeze_left -= delta
		if freeze_left <= 0.0:
			freeze_left = 0.0
			freeze_enemy = false
	if spade_left > 0.0:
		spade_left -= delta
		if spade_left <= 0.0:
			spade_left = 0.0
			_restore_base_walls()
	if win_left > 0.0:
		win_left -= delta
		if win_left <= 0.0:
			win_left = -1.0
			if main != null:
				main.show_success()
			state = "over"

func _try_spawn_enemy() -> void:
	if enemy_num >= TankConfig.MAX_ENEMY:
		return
	var p: Vector2 = TankConfig.spawn_points()[randi() % 3]
	var blockers: Array = []
	for e in world.in_rect(Rect2(p.x, p.y, 39, 39)):
		if ["PLAYER", "ENEMY", "STONE", "BRICK", "SEA"].has(e.entity_type):
			blockers.append(e)
	if blockers.is_empty():
		spawn_enemy(p)
		enemy_num += 1
		info.set_enemy_num(enemy_num)

func _resolve_collisions() -> void:
	for b in world.by_type("BULLET"):
		if not is_instance_valid(b):
			continue
		for e in world.entities.duplicate():
			if not is_instance_valid(e) or e == b:
				continue
			if not b.overlaps(e):
				continue
			var handled := true
			match e.entity_type:
				"ENEMY":
					if b.owner_type == "PLAYER":
						_hit_enemy(e as Tank, b)
						world.remove(b)
					else:
						handled = false
				"PLAYER":
					if b.owner_type == "ENEMY":
						_hit_player(b, e as Tank)
					else:
						handled = false
				"BULLET":
					if b.owner_type != e.owner_type:
						world.remove(b)
						world.remove(e)
					else:
						handled = false
				"BORDER":
					world.remove(b)
				"FLAG":
					_hit_flag(e)
					world.remove(b)
					game_over()
				"BRICK", "STONE", "GREENS":
					_bullet_brick_handler(b)
				_:
					handled = false
			if handled:
				break
	for item in world.by_type("ITEM"):
		if not is_instance_valid(item):
			continue
		for t in world.by_types(["PLAYER", "ENEMY"]):
			if not is_instance_valid(t):
				continue
			if item.overlaps(t):
				_apply_item(item as Item, t as Tank)
				break

func _hit_player(b: Bullet, p: Tank) -> void:
	if p.helmet_left > 0.0:
		world.remove(b)
		return
	p.damage(1)
	world.remove(b)
	if p.hp <= 0:
		world.remove(p)
		spawn_explode(p.center() - Vector2(25, 25), true)
		game_over()

func _hit_enemy(e: Tank, b: Bullet) -> void:
	# Every hit removes one HP; a max-level bullet destroys any tank in one shot
	# (matches the classic "full power = instant kill" feel).
	var dmg: int = 3 if b.level >= TankConfig.TANK_MAX_LEVEL else 1
	e.damage(dmg)
	if e.hp > 0:
		return
	spawn_explode(e.center() - Vector2(25, 25), true)
	world.remove(e)
	destroyed += 1
	if randf() < 0.5:
		spawn_item(Vector2(randf_range(24, 24 + 618), randf_range(24, 24 + 620)))
	if destroyed == TankConfig.MAX_ENEMY:
		TankSound.play("Win.wav", self)
		win_left = 1.0

func _hit_flag(flag: TankEntity) -> void:
	flag.set_texture(load("res://assets/textures/map/flag_failed.png"))
	spawn_explode(flag.center() - Vector2(25, 25), true)

func _bullet_brick_handler(b: Bullet) -> void:
	var remove_bullet := false
	for e in world.entities.duplicate():
		if not is_instance_valid(e):
			continue
		if not b.overlaps(e):
			continue
		match e.entity_type:
			"BRICK":
				world.remove(e)
				remove_bullet = true
			"STONE":
				if b.level >= TankConfig.TANK_MAX_LEVEL:
					world.remove(e)
				remove_bullet = true
			"GREENS":
				if b.level >= TankConfig.TANK_MAX_LEVEL:
					world.remove(e)
	if remove_bullet:
		spawn_explode(b.center() - Vector2(25, 25), true)
		world.remove(b)

func _apply_item(item: Item, t: Tank) -> void:
	TankSound.play("item.wav", self)
	world.remove(item)
	if t.is_player:
		match item.item_type:
			"STAR":
				t.level = mini(TankConfig.TANK_MAX_LEVEL, t.level + 1)
				info.set_bullet_level(t.level)
			"GUN":
				t.level = TankConfig.TANK_MAX_LEVEL
				info.set_bullet_level(t.level)
			"TANK":
				t.hp = mini(TankConfig.PLAYER_HP, t.hp + 1)
				t.refresh_hp_bar()
			"HEART":
				t.hp = TankConfig.PLAYER_HP
				t.refresh_hp_bar()
			"BOMB":
				for e in world.by_type("ENEMY"):
					spawn_explode((e as Tank).center(), false)
					world.remove(e)
					destroyed += 1
				if destroyed >= TankConfig.MAX_ENEMY:
					TankSound.play("Win.wav", self)
					win_left = 1.0
			"SHIP":
				t.set_ship(true)
			"TIME":
				freeze_left = TankConfig.FREEZE_TIME
				freeze_enemy = true
			"HELMET":
				t.set_helmet(TankConfig.HELMET_TIME)
			"SPADE", _:
				reinforce()
	else:
		match item.item_type:
			"STAR":
				t.level = mini(TankConfig.TANK_MAX_LEVEL, t.level + 1)
			"GUN":
				t.level = TankConfig.TANK_MAX_LEVEL
			"TANK", "HEART", "BOMB":
				for p in world.by_type("PLAYER"):
					if not is_instance_valid(p):
						continue
					var pl := p as Tank
					if item.item_type == "TANK":
						pl.damage(1)
					elif item.item_type == "HEART":
						pl.damage(pl.hp / 2)
					else:
						pl.hp = 1
						pl.refresh_hp_bar()
					if pl.hp <= 0:
						world.remove(t)
						spawn_explode(t.center() - Vector2(25, 25), true)
						game_over()
			"SHIP":
				t.set_ship(true)
			"TIME":
				for p in world.by_type("PLAYER"):
					if is_instance_valid(p):
						(p as Tank).freeze_left = TankConfig.ENEMY_FREEZE_TIME
			"HELMET":
				t.set_helmet(TankConfig.HELMET_TIME)
			"SPADE":
				unreinforce()
			_:
				pass

func reinforce() -> void:
	spade_left = TankConfig.SPADE_TIME
	var brick: Texture2D = load("res://assets/textures/map/brick.png")
	for p in TankConfig.base_wall_points():
		for e in world.at(p):
			world.remove(e)
		var e := TankEntity.new()
		e.world_ref = world
		e.configure("STONE", Vector2(TankConfig.CELL, TankConfig.CELL), brick)
		e.position = p
		world.add(e)

func _restore_base_walls() -> void:
	var brick: Texture2D = load("res://assets/textures/map/brick.png")
	for p in TankConfig.base_wall_points():
		for e in world.at(p):
			world.remove(e)
		var e := TankEntity.new()
		e.world_ref = world
		e.configure("BRICK", Vector2(TankConfig.CELL, TankConfig.CELL), brick)
		e.position = p
		world.add(e)

func unreinforce() -> void:
	for p in TankConfig.base_wall_points():
		for e in world.at(p):
			world.remove(e)

func game_over() -> void:
	state = "over"
	if main != null:
		main.show_failed()

func handle_key(event: InputEventKey) -> void:
	if state != "playing" or player == null:
		return
	if event.echo or not event.pressed:
		return
	# Movement is polled each frame in _process (Input.is_key_pressed) so holding
	# a key moves continuously. Handling key-down here too would double-step.
	if event.keycode == KEY_SPACE:
		player.shoot()
