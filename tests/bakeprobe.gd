extends SceneTree
## BAKEPROBE — isolate street assembly + bake for ONE street type.
## Prints the mesh count before and after bake_static so a merge failure is
## visible as a number instead of an inferred difference between districts.
##   TYPE=5 LEN=78 godot --headless --script res://tests/bakeprobe.gd

func _initialize() -> void:
	var w = load("res://scenes/world.tscn").instantiate()
	w.set_script(null)
	var kit_script = load("res://scripts/world/street_kit.gd")
	var kit = kit_script.new()
	w.add_child(kit)
	var type := int(OS.get_environment("TYPE") if OS.get_environment("TYPE") != "" else "0")
	var length := float(OS.get_environment("LEN") if OS.get_environment("LEN") != "" else "78")
	kit.set_seed(1234)
	var t := Time.get_ticks_msec()
	var st = kit.build_street(Vector3.ZERO, Vector3(1, 0, 0), length, type)
	print("B built meshes=", _meshes(kit), " ms=", Time.get_ticks_msec() - t)
	var t2 := Time.get_ticks_msec()
	var baked: int = kit.bake_static(kit)
	print("B baked_groups=", baked, " meshes_after=", _meshes(kit), " ms=", Time.get_ticks_msec() - t2)
	# Diagnose exactly which guard in bake_static rejects the meshes.
	var seen := 0
	var null_mesh := 0
	var skinned := 0
	var no_override := 0
	var stack: Array = [kit]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is MeshInstance3D:
			seen += 1
			var mi := n as MeshInstance3D
			if mi.mesh == null: null_mesh += 1
			if mi.skeleton != NodePath(): skinned += 1
			if mi.material_override == null: no_override += 1
	print("B seen=%d null_mesh=%d skinned=%d no_override=%d" % [seen, null_mesh, skinned, no_override])
	print("B done")
	quit()

func _meshes(n: Node) -> int:
	var c := 0
	if n is MeshInstance3D:
		c = 1
	for ch in n.get_children():
		c += _meshes(ch)
	return c
