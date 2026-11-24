extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	for ty in [0, 5]:
		var t1 := Time.get_ticks_msec()
		var s = kit.get_street(ty, 0, 78.0)
		print("build type ", ty, " ms=", Time.get_ticks_msec() - t1)
		t1 = Time.get_ticks_msec()
		for i in 4:
			var d = kit.get_street(ty, i, 78.0)
			d.free()
		print("  four dupes type ", ty, " ms=", Time.get_ticks_msec() - t1)
		s.free()
	quit()
