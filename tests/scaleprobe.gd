extends SceneTree
func _init():
	var ps = load("res://assets/characters/players/casual-male.glb")
	var inst = ps.instantiate()
	var sms: Array = inst.find_children("*", "MeshInstance3D", true, false)
	for n in sms:
		var mi := n as MeshInstance3D
		var aabb: AABB = mi.mesh.get_aabb() if mi.mesh != null else AABB()
		print("mesh ", mi.name, " size=", aabb.size, " skel=", mi.skeleton)
	# bone extents tell us the authored height directly
	var sk: Skeleton3D = null
	for n in inst.find_children("*", "Skeleton3D", true, false):
		sk = n as Skeleton3D
	if sk != null:
		var lo := 1e9
		var hi := -1e9
		for b in sk.get_bone_count():
			var p := sk.get_bone_global_rest(b).origin
			lo = minf(lo, p.y); hi = maxf(hi, p.y)
		print("BONE Y range ", lo, " .. ", hi, "  height=", hi - lo, " bones=", sk.get_bone_count())
	inst.free()
	quit()
