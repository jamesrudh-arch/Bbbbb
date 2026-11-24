extends SceneTree
func _init():
	# same kit instance reused for four variants, like get_street does
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	for v in range(4):
		var t1 := Time.get_ticks_msec()
		var k = load("res://scripts/world/street_kit.gd").new()
		k.set_seed(hash("5_%d_78" % v))
		kit.add_child(k)
		k.build_street(Vector3.ZERO, Vector3(1,0,0), 78.0, 5)
		print("nested build v", v, " ms=", Time.get_ticks_msec() - t1)
		kit.bake_static(k)
	quit()
