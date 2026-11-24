extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	kit.build_street(Vector3.ZERO, Vector3(1,0,0), 62.0, 0)
	var people := 0
	var skinned := 0
	var mesh_total := 0
	var stack: Array = [kit]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children(): stack.append(ch)
		if n is MeshInstance3D:
			mesh_total += 1
			if (n as MeshInstance3D).skeleton != NodePath(): skinned += 1
			if n.get_parent() != null and n.get_parent().get_parent() != null \
				and str(n.get_parent().get_parent().name) == "People":
				people += 1
	print("MESHES=", mesh_total, " SKINNED=", skinned, " people_meshes=", people)
	var pr = null
	for c in kit.get_children():
		if str(c.name) == "People": pr = c
	if pr != null:
		print("PEOPLE_ROWS=", pr.get_child_count())
		for i in mini(3, pr.get_child_count()):
			var p: Node3D = pr.get_child(i)
			print("  person ", i, " pos=", p.position, " children=", p.get_child_count())
	quit()
