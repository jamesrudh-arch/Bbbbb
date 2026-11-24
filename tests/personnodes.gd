extends SceneTree
func _init():
	var ps = load("res://assets/characters/players/casual-male.glb")
	var inst = ps.instantiate()
	var by_type := {}
	var total := 0
	var stack: Array = [inst]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		total += 1
		var k: String = n.get_class()
		by_type[k] = by_type.get(k, 0) + 1
		for ch in n.get_children(): stack.append(ch)
	print("PERSON nodes=", total)
	for k in by_type:
		print("   ", k, " x", by_type[k])
	inst.free()
	quit()
