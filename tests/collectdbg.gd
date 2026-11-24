extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	print("D obj index=", Game.objective_index(), " type=", Game.current_objective().get("type", ""))
	# jump to the collect objective directly
	Game.mission["index"] = 2
	Game.mission["progress"] = 0
	print("D now type=", Game.current_objective().get("type", ""), " count=", Game.current_objective().get("count", 1))
	var collected := 0
	for p in w.pickups.pickups.duplicate():
		var node = p.get("node")
		if not is_instance_valid(node): continue
		w.interactables.activate(node, w.player)
		collected += 1
		await get_tree().process_frame
		print("D  after collect ", collected, ": progress=", Game.mission.get("progress", -1), " index=", Game.objective_index())
		if Game.objective_index() != 2: break
	print("D final index=", Game.objective_index(), " collectibles=", Game.collectibles.size())
	get_tree().quit()
