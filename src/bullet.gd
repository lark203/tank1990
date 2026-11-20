class_name Bullet
extends TankEntity

var velocity: Vector2 = Vector2.ZERO

func setup(pos: Vector2, dir: Vector2, lvl: int, owner: String) -> void:
	configure("BULLET", Vector2(TankConfig.BULLET_W, TankConfig.BULLET_H), load("res://assets/textures/bullet/normal.png"))
	position = pos
	velocity = dir * TankConfig.BULLET_SPEED
	level = lvl
	owner_type = owner
	rotation = Vector2(0, -1).angle_to(dir)

func step(delta: float) -> void:
	position += velocity * delta
