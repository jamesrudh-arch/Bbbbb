extends Node
## A real session: the actual world, 3,600 frames of continuous play, driving
## the player through all four quadrants so streaming, crowds, traffic, the night
## cycle and collision all get exercised. Report every error and warning.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	var dirs := [Vector3(1,0,0), Vector3(0,0,1), Vector3(-1,0,0), Vector3(0,0,-1)]
	var t0 := Time.get_ticks_msec()
	for f in 3600:
		if not is_instance_valid(world): break
		var d: Vector3 = dirs[int(f / 900) % 4]
		if world.player != null:
			world.player.velocity.x = d.x * 6.0
			world.player.velocity.z = d.z * 6.0
		await get_tree().process_frame
	var dt := Time.get_ticks_msec() - t0
	print("K frames=3600 in ", dt, " ms = ", snappedf(3600.0 * 1000.0 / maxf(dt, 1.0), 0.1), " fps")
	print("K districts live=", world.districts.size(), " fragments=", world.pickups.pickups.size())
	print("K money=", Game.money, " collectibles=", Game.collectibles.size(), " flags=", Game.flags.size())
	# Tear the world down the way a real session ends (back to the menu), then
	# check for leaks. Quitting straight to process exit leaves the whole scene
	# alive at teardown, which Godot reports as leaked - a measurement artifact
	# of the test, not of the game.
	print("K orphans during play=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("K orphans after teardown=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("K done")
	get_tree().quit()
