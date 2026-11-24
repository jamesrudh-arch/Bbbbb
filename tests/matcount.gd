extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	kit.set_seed(20261123)
	get_root().add_child(kit)
	kit.build_street(Vector3(0,0,0), Vector3(1,0,0), 78.0, 0)
	var meshes := 0
	var null_mat := 0
	var ids := {}
	var stack: Array = [kit]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children(): stack.append(ch)
		if n is MeshInstance3D:
			meshes += 1
			var mi := n as MeshInstance3D
			if mi.material_override == null:
				null_mat += 1
			else:
				ids[mi.material_override.get_instance_id()] = true
	print("meshes=", meshes, " distinct_mat_objects=", ids.size(), " null_material_meshes=", null_mat, " cache=", kit._mat_cache.size())
	quit()
