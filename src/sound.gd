class_name TankSound
extends RefCounted

static var streams: Dictionary = {}

static func play(name: String, parent: Node) -> void:
	if not streams.has(name):
		var path := "res://assets/sounds/" + name
		if not ResourceLoader.exists(path):
			return
		streams[name] = load(path)
	var player := AudioStreamPlayer.new()
	player.stream = streams[name]
	parent.add_child(player)
	player.play()
	player.finished.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)
