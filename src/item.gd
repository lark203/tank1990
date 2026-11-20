class_name Item
extends TankEntity

var life: float = TankConfig.ITEM_LIFE

func setup(pos: Vector2, kind: String) -> void:
	item_type = kind
	var tex: Texture2D = load("res://assets/textures/item/" + kind.to_lower() + ".png")
	configure("ITEM", Vector2(tex.get_width(), tex.get_height()), tex)
	position = pos

func tick(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		if world_ref != null:
			world_ref.remove(self)
