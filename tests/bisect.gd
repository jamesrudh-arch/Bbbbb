extends SceneTree
func _initialize():
	var skip := OS.get_environment("SKIP")
	print("BISECT skip=", skip)
	var w = load("res://scenes/world.tscn").instantiate()
	if skip != "":
		for nm in skip.split(","):
			var n = w.get(nm)
			if n != null:
				w.remove_child(n)
				n.free()
				print("  removed ", nm)
	get_root().add_child(w)
	print("BISECT added nodes=", _c(get_root()))
func _process(_d: float) -> bool:
	print("BISECT FRAME OK")
	return true
func _c(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _c(ch)
	return c
