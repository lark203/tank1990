class_name TankWorld
extends Node

# Flat entity list. FXGL collision handlers are emulated explicitly in game.gd so
# the observable behaviour (including ambiguities) matches the Java implementation.

var entities: Array = []

func add(e: TankEntity) -> TankEntity:
	entities.append(e)
	add_child(e)
	return e

func remove(e: TankEntity) -> void:
	var idx := entities.find(e)
	if idx >= 0:
		entities.remove_at(idx)
	if is_instance_valid(e):
		e.queue_free()

func clear() -> void:
	for e in entities.duplicate():
		remove(e)
	entities.clear()

func by_type(t: String) -> Array:
	var result: Array = []
	for e in entities:
		if is_instance_valid(e) and e.entity_type == t:
			result.append(e)
	return result

func by_types(types: Array) -> Array:
	var result: Array = []
	for e in entities:
		if is_instance_valid(e) and types.has(e.entity_type):
			result.append(e)
	return result

func at(p: Vector2) -> Array:
	var result: Array = []
	for e in entities:
		if is_instance_valid(e) and Rect2(e.position, e.box_size).has_point(p):
			result.append(e)
	return result

func in_rect(r: Rect2) -> Array:
	var result: Array = []
	for e in entities:
		if is_instance_valid(e) and Rect2(e.position, e.box_size).intersects(r):
			result.append(e)
	return result
