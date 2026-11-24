extends Node
## End to end: boot -> menu -> world -> opening mission -> reward -> autosave ->
## jobs board -> job start. 14 checks, against the real scenes.
var ok := 0
var bad := 0

func _c(name: String, cond: bool, detail := "") -> void:
	if cond:
		ok += 1; print("G  ok   ", name, (" — " + detail if detail else ""))
	else:
		bad += 1; print("G  FAIL ", name, (" — " + detail if detail else ""))

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	# ---- boot stage machine, on a plain node (the scene's ready runs the real
	# presentational flow, which is right for a player and wrong for a probe)
	if FileAccess.file_exists("user://notice_seen.save"):
		DirAccess.remove_absolute("user://notice_seen.save")
	var boot = load("res://scripts/ui/boot.gd").new()
	add_child(boot)
	await get_tree().process_frame
	_c("boot starts at studio", int(boot.get("_stage")) == 0)
	boot.call("_advance")
	await get_tree().process_frame
	_c("boot advances to title", int(boot.get("_stage")) == 1)
	boot.call("_advance")
	await get_tree().process_frame
	_c("first launch shows the notice", int(boot.get("_stage")) == 2)
	DirAccess.remove_absolute("user://notice_seen.save")
	var f := FileAccess.open("user://notice_seen.save", FileAccess.WRITE)
	f.store_string("1"); f.close()
	boot.queue_free()
	await get_tree().process_frame

	var boot2 = load("res://scripts/ui/boot.gd").new()
	boot2.set("_depart_disabled", true)
	add_child(boot2)
	await get_tree().process_frame
	boot2.call("_advance")
	await get_tree().process_frame
	_c("second launch skips the notice", int(boot2.get("_stage")) == 3,
		"stage " + str(boot2.get("_stage")))
	boot2.queue_free()
	await get_tree().process_frame

	# ---- world
	Game.reset_new_game()
	Game.start_mission("homecoming")
	var t := Time.get_ticks_msec()
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	_c("world loads", world.districts.size() == 6,
		"%d districts in %d ms" % [world.districts.size(), Time.get_ticks_msec() - t])
	_c("player exists", world.player != null)
	_c("hud exists", world.hud != null)
	_c("opening mission active", str(Game.mission.get("id", "")) == "homecoming")

	for i in 20:
		await get_tree().process_frame

	# ---- play the opening mission
	var guard := 0
	while not Game.mission.is_empty() and guard < 12:
		guard += 1
		var obj: Dictionary = Game.current_objective()
		if obj.is_empty(): break
		var kind := str(obj.get("type", ""))
		var before := Game.objective_index()
		match kind:
			"reach":
				world.player.global_position = world.missions._target_position(str(obj.get("target", "")))
				world.missions._check_reach(obj)
			"talk":
				world.missions.report_talk(str(obj.get("target", "")))
			"collect":
				for i2 in int(obj.get("count", 1)):
					if world.pickups.pickups.is_empty(): break
					world.interactables.activate(world.pickups.pickups[0].get("node"), world.player)
			"fight":
				for tgt in world.missions._fight_targets:
					if is_instance_valid(tgt) and tgt.has_method("die"): tgt.die()
			_:
				Game.advance_mission()
		var waited := 0
		while Game.objective_index() == before and not Game.mission.is_empty() and waited < 120:
			await get_tree().process_frame
			waited += 1
		if waited >= 120:
			print("G  stuck on objective ", before, " type=", kind)
			break
	_c("homecoming completes", Game.completed_missions.has("homecoming"), str(Game.completed_missions))
	_c("reward paid", Game.money > 120, "money=" + str(Game.money))
	_c("next mission unlocked", Game.mission_available("short_count"))
	_c("autosave on completion", Game.latest_save_slot() == Game.AUTOSAVE_SLOT,
		"slot " + str(Game.latest_save_slot()))

	var jobs: Array = world.hud._available_jobs()
	_c("jobs on the board", jobs.size() > 0, str(jobs.size()))
	if jobs.size() > 0:
		var jid: String = str(jobs[0])
		Game.start_mission_from_job(jid, Content.SIDE_JOBS[jid])
		_c("job starts", str(Game.mission.get("id", "")).begins_with("job_"),
			str(Game.mission.get("id", "")))

	print("G ---- %d ok, %d failed ----" % [ok, bad])
	get_tree().quit(1 if bad > 0 else 0)
