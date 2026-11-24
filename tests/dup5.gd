extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	for v in range(4):
		var t1 := Time.get_ticks_msec()
		var s = kit.get_street(5, v, 78.0)
		print("v", v, " get_street ms=", Time.get_ticks_msec() - t1, " kids=", s.get_child_count())
		s.free()
	quit()
