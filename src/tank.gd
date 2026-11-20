class_name Tank
extends TankEntity

var is_player: bool = false
var hp: int = TankConfig.PLAYER_HP
var max_hp: int = TankConfig.PLAYER_HP
var enemy_kind: String = ""       # NORMAL / FAST / ARMOR / POWER (enemies only)
var move_speed: float = TankConfig.TANK_MOVE_SPEED
var move_dir: String = TankConfig.DIR_UP
var shoot_elapsed: float = 999.0
var moved_this_frame: bool = false
var distance_per_frame: float = 0.0
var freeze_left: float = 0.0
var helmet_left: float = 0.0
var ship: bool = false
var game_ref: Node = null
var hp_bg: ColorRect = null
var hp_fill: ColorRect = null
var helmet_anim: AnimatedSprite2D = null
var ship_sprite: Sprite2D = null

func setup(player: bool, world: TankWorld, game: Node, texture: Texture2D, kind: String = "") -> void:
	is_player = player
	world_ref = world
	game_ref = game
	configure("PLAYER" if player else "ENEMY", Vector2(TankConfig.TANK_SIZE, TankConfig.TANK_SIZE), texture)
	if not player and kind != "" and TankConfig.ENEMY_TYPES.has(kind):
		var cfg: Dictionary = TankConfig.ENEMY_TYPES[kind]
		enemy_kind = kind
		hp = int(cfg["hp"])
		max_hp = hp
		move_speed = float(cfg["speed"])
		level = int(cfg["level"])
	# Rotate the sprite around the tank centre, not the entity's top-left corner.
	# Entity position stays top-left so AABB/collision semantics are unchanged.
	if sprite != null:
		sprite.centered = true
		sprite.position = Vector2(TankConfig.TANK_SIZE, TankConfig.TANK_SIZE) / 2.0
		sprite.rotation = TankConfig.dir_rotation(move_dir)
	# Both sides show a small HP bar so the armour difference is visible.
	_build_hp_bar()

func _build_hp_bar() -> void:
	hp_bg = ColorRect.new()
	hp_bg.position = Vector2(0, 39)
	hp_bg.size = Vector2(39, 8)
	hp_bg.color = Color(0.18, 0.18, 0.18, 0.75)
	add_child(hp_bg)
	hp_fill = ColorRect.new()
	hp_fill.position = Vector2(0, 39)
	hp_fill.size = Vector2(39, 8)
	hp_fill.color = Color.html("#90EE90")
	add_child(hp_fill)
	refresh_hp_bar()

func refresh_hp_bar() -> void:
	if hp_fill == null:
		return
	hp_fill.size.x = 39.0 * float(maxi(0, hp)) / float(maxi(1, max_hp))
	if is_player:
		if hp <= 2:
			hp_fill.color = Color.html("#FF0000")
		elif hp == 3:
			hp_fill.color = Color.html("#FFFFE0")
		else:
			hp_fill.color = Color.html("#90EE90")
	else:
		# Enemy bar: colour hints at the tank class (red = fragile, orange =
		# armoured, purple = heavy) while width shows remaining HP.
		match enemy_kind:
			"POWER": hp_fill.color = Color.html("#9B30FF")
			"ARMOR": hp_fill.color = Color.html("#FF8C00")
			"FAST": hp_fill.color = Color.html("#FFD700")
			_: hp_fill.color = Color.html("#FF4040")

func tick(delta: float) -> void:
	# TankComponent.onUpdate runs before EnemyComponent.onUpdate in FXGL.
	if freeze_left > 0.0:
		freeze_left = maxf(0.0, freeze_left - delta)
	if helmet_left > 0.0:
		helmet_left = maxf(0.0, helmet_left - delta)
		if helmet_left == 0.0:
			remove_helmet()
	shoot_elapsed += delta
	moved_this_frame = false
	distance_per_frame = delta * move_speed

func enemy_update(_delta: float) -> void:
	if game_ref != null and game_ref.freeze_enemy:
		return
	if randf() < 0.025:
		var dirs := [TankConfig.DIR_UP, TankConfig.DIR_DOWN, TankConfig.DIR_LEFT, TankConfig.DIR_RIGHT]
		move_dir = dirs[randi() % 4]
	try_move(move_dir)
	if randf() < 0.03:
		shoot()

func try_move(dir: String) -> void:
	if moved_this_frame:
		return
	moved_this_frame = true
	if sprite != null:
		sprite.rotation = TankConfig.dir_rotation(dir)
	move_dir = dir
	move()

func move() -> void:
	var steps: int = int(distance_per_frame)
	var vec := TankConfig.dir_vector(move_dir)
	var block_types := ["BORDER", "BRICK", "STONE", "PLAYER", "ENEMY"]
	if not ship:
		block_types.append("SEA")
	var blocks: Array = world_ref.by_types(block_types)
	blocks.erase(self)
	var collided := false
	for _i in range(steps):
		position += vec
		for b in blocks:
			if is_instance_valid(b) and overlaps(b):
				collided = true
				break
		if collided:
			position -= vec
			break
	# FXGL moves by fractional pixels too (speed * delta); keep the remainder
	# instead of truncating to int, otherwise 150px/s becomes ~120px/s at 60fps.
	var frac: float = distance_per_frame - float(steps)
	if not collided and frac > 0.0:
		position += vec * frac
		for b in blocks:
			if is_instance_valid(b) and overlaps(b):
				position -= vec * frac
				break

func shoot() -> void:
	if shoot_elapsed < TankConfig.SHOOT_DELAY:
		return
	shoot_elapsed = 0.0
	if game_ref != null:
		var spawn_pos: Vector2 = center() - Vector2(4, 5)
		game_ref.spawn_bullet(spawn_pos, TankConfig.dir_vector(move_dir), level, entity_type)

func damage(amount: int) -> void:
	hp -= amount
	refresh_hp_bar()

func set_ship(on: bool) -> void:
	ship = on
	if on and ship_sprite == null:
		var tex: Texture2D = load("res://assets/textures/item/armed_ship.png")
		ship_sprite = Sprite2D.new()
		ship_sprite.texture = tex
		ship_sprite.centered = false
		ship_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ship_sprite.position = Vector2(39.0 / 2.0 - tex.get_width() / 2.0, 39.0 / 2.0 - tex.get_height() / 2.0)
		add_child(ship_sprite)
	elif not on and ship_sprite != null:
		ship_sprite.queue_free()
		ship_sprite = null

func set_helmet(duration: float) -> void:
	helmet_left = duration
	if helmet_anim != null:
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("play")
	frames.set_animation_speed("play", 8.0)
	var tex: Texture2D = load("res://assets/textures/item/armed_helmet.png")
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 51, 0, 51, 48)
		frames.add_frame("play", atlas)
	helmet_anim = AnimatedSprite2D.new()
	helmet_anim.sprite_frames = frames
	helmet_anim.centered = false
	helmet_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	helmet_anim.position = Vector2(39.0 / 2.0 - 51.0 / 2.0, 39.0 / 2.0 - 48.0 / 2.0)
	add_child(helmet_anim)
	helmet_anim.play("play")

func remove_helmet() -> void:
	if helmet_anim != null:
		helmet_anim.queue_free()
		helmet_anim = null
