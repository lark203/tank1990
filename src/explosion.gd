class_name Explosion
extends TankEntity

var life: float = 0.5

func setup(pos: Vector2, big: bool) -> void:
	configure("EXPLODE", Vector2(50, 50))
	position = pos
	var path := "res://assets/textures/explode/explode_level_2.png" if big else "res://assets/textures/explode/explode_level_1.png"
	var count: int = 9 if big else 5
	var tex: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("play")
	frames.set_animation_speed("play", float(count) / 0.5)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 50, 0, 50, 50)
		frames.add_frame("play", atlas)
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = frames
	anim.centered = false
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim)
	anim.play("play")

func tick(delta: float) -> void:
	life -= delta
	if life <= 0.0 and world_ref != null:
		world_ref.remove(self)
