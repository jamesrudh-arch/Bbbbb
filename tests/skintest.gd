extends Node
func _ready():
	var mode := OS.get_environment("SKINTEST")
	print("SKIN mode=", mode)
	if mode != "none":
		var kit = load("res://scripts/world/street_kit.gd").new()
		add_child(kit)
		var n := 36
		if mode == "few": n = 6
		for i in n:
			kit.person(Vector3(i * 2.0, 0, 0), 0.0, null, "casual-male")
		print("SKIN spawned ", n)
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while frames < 2 and Time.get_ticks_msec() - t0 < 40000:
		await get_tree().process_frame
		frames += 1
	print("SKIN frames=", frames, " ms=", Time.get_ticks_msec() - t0)
	get_tree().quit()
