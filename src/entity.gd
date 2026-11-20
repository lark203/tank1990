class_name TankEntity
extends Node2D

# Generic entity mirroring FXGL's TypeComponent + BoundingBoxComponent + ViewComponent.
# position is the top-left corner, exactly like FXGL entity position.

var entity_type: String = ""
var box_size: Vector2 = Vector2(24, 24)
var world_ref: TankWorld = null
var level: int = 1
var owner_type: String = ""
var item_type: String = ""
var sprite: Sprite2D = null
var anim: AnimatedSprite2D = null

func configure(t: String, size: Vector2, texture: Texture2D = null) -> void:
	entity_type = t
	box_size = size
	if texture != null:
		sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)

func set_texture(texture: Texture2D) -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	sprite.texture = texture

func rect() -> Rect2:
	return Rect2(position, box_size)

func center() -> Vector2:
	return position + box_size * 0.5

func overlaps(other: TankEntity) -> bool:
	return rect().intersects(other.rect())
