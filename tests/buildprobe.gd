extends SceneTree
func _init():
	var t0 := Time.get_ticks_msec()
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	print("kit instantiate ms=", Time.get_ticks_msec() - t0)
	for ty in range(6):
		var t1 := Time.get_ticks_msec()
		var s: Node3D = kit.get_street(ty, 0, 78.0)
		var t2 := Time.get_ticks_msec()
		print("type ", ty, " build+bake ms=", t2 - t1)
		s.free()
	print("total ms=", Time.get_ticks_msec() - t0)
	quit()
