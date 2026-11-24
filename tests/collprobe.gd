extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	kit.build_street(Vector3.ZERO, Vector3(1,0,0), 62.0, 0)
	var bodies := 0
	var shapes := 0
	var stack: Array = [kit]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children(): stack.append(ch)
		if n is CollisionObject3D: bodies += 1
		if n is CollisionShape3D: shapes += 1
	print("COLLISION bodies=", bodies, " shapes=", shapes)
	quit()
