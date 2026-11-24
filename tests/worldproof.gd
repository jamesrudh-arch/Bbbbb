extends Node
## Does the real world build and run? Node count, districts, fragments, mission.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var t := Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := 0
	var stack: Array = [w]
	while stack.size() > 0:
		var x: Node = stack.pop_back(); n += 1
		for c in x.get_children(): stack.append(c)
	print("W nodes=", n, " districts=", w.districts.size(), " ms=", Time.get_ticks_msec() - t)
	print("W fragments=", w.pickups.pickups.size(), " npcs=", w.npcs.named.size())
	print("W mission=", Game.mission.get("id", "none"))
	var err := 0
	for f in 900:
		if w.player != null:
			w.player.velocity.x = 4.0 if (f / 300) % 2 == 0 else -4.0
		await get_tree().process_frame
	print("W survived 900 frames, districts still live=", w.districts.size())
	print("W done")
	get_tree().quit()
