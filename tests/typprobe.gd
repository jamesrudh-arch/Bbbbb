extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	for ty in range(6):
		var t1 := Time.get_ticks_msec()
		var s = kit.get_street(ty, 0, 78.0)
		print("get_street type ", ty, " ms=", Time.get_ticks_msec() - t1)
		s.free()
	quit()
