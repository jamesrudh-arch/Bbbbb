extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	for v in range(4):
		var t1 := Time.get_ticks_msec()
		kit.set_seed(hash("5_%d_78" % v))
		var k = load("res://scripts/world/street_kit.gd").new()
		k.set_seed(hash("5_%d_78" % v))
		get_root().add_child(k)
		k.build_street(Vector3.ZERO, Vector3(1,0,0), 78.0, 5)
		print("variant ", v, " built ms=", Time.get_ticks_msec() - t1)
		t1 = Time.get_ticks_msec()
		k.bake_static(k)
		print("  baked ms=", Time.get_ticks_msec() - t1)
		k.free()
	quit()
