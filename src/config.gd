class_name TankConfig
extends RefCounted

# All numbers below are copied verbatim from leo-0019-tank2/src/main/java/com/leo/common/Config.java
# and PlayerEntityFactory/TankComponent/EnemyComponent. game.properties is NOT read by the Java code.

const FIELD_W := 672
const FIELD_H := 672
const PANEL_W := 144
const CELL := 24
const TANK_MOVE_SPEED := 150.0
const BULLET_SPEED := 400.0
const SHOOT_DELAY := 0.35
const MAX_ENEMY := 10
const INIT_ENEMY := 3
const SPAWN_INTERVAL := 3.0
const MAX_LEVEL := 6
const TANK_MAX_LEVEL := 3

# Enemy types by sprite colour (4 classic FC tank types).
# weight: spawn probability; hp: hits to kill; speed: px/s; level: bullet level.
const ENEMY_TYPES := {
	"NORMAL": {"hp": 1, "speed": 150.0, "level": 1, "weight": 50,
		"textures": ["E1U.png", "E2U.png", "E5U.png", "E6U.png", "E10U.png", "E11U.png"]},
	"FAST": {"hp": 1, "speed": 240.0, "level": 1, "weight": 20,
		"textures": ["E4U.png", "E7U.png"]},
	"ARMOR": {"hp": 2, "speed": 150.0, "level": 1, "weight": 15,
		"textures": ["E8U.png"]},
	"POWER": {"hp": 3, "speed": 150.0, "level": 3, "weight": 15,
		"textures": ["E3U.png", "E9U.png", "E12U.png"]},
}

# Map-wide random item drops (independent of kill drops).
const ITEM_SPAWN_INTERVAL := 10.0
const ITEM_MAX_ON_FIELD := 3
const TANK_INIT_LEVEL := 1
const PLAYER_HP := 5
const ITEM_LIFE := 25.0
const FREEZE_TIME := 10.0
const HELMET_TIME := 12.0
const SPADE_TIME := 15.0
const ENEMY_FREEZE_TIME := 3.0
const TANK_SIZE := 39.0
const BULLET_W := 8.0
const BULLET_H := 10.0
const FLAG_SIZE := 48.0
const EXPLODE_FRAME_TIME := 0.5 / 9.0
const BOMB_FRAME_TIME := 0.5 / 5.0

const DIR_UP := "UP"
const DIR_DOWN := "DOWN"
const DIR_LEFT := "LEFT"
const DIR_RIGHT := "RIGHT"

static func spawn_points() -> Array:
	return [Vector2(30, 30), Vector2(330, 30), Vector2(580, 30)]

static func base_wall_points() -> Array:
	return [
		Vector2(288, 576), Vector2(288, 600), Vector2(288, 624),
		Vector2(312, 576), Vector2(336, 576), Vector2(360, 576),
		Vector2(360, 600), Vector2(360, 624),
	]

static func dir_vector(dir: String) -> Vector2:
	match dir:
		DIR_UP: return Vector2(0, -1)
		DIR_DOWN: return Vector2(0, 1)
		DIR_LEFT: return Vector2(-1, 0)
		DIR_RIGHT: return Vector2(1, 0)
	return Vector2.ZERO

static func dir_rotation(dir: String) -> float:
	match dir:
		DIR_UP: return 0.0
		DIR_DOWN: return deg_to_rad(180.0)
		DIR_LEFT: return deg_to_rad(270.0)
		DIR_RIGHT: return deg_to_rad(90.0)
	return 0.0
