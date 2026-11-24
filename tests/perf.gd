extends SceneTree
var kit
func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count(ch)
	return c
func _meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _meshes(ch)
	return c
func _init():
	for ty in [0, 1, 4]:
		kit = load("res://scripts/world/street_kit.gd").new()
		kit.set_seed(20261123)
		get_root().add_child(kit)
		kit.build_street(Vector3(0,0,0), Vector3(1,0,0), 78.0, ty)
		var before := _meshes(kit)
		var materials: int = kit.bake_static(kit)
		print("type ", ty, " meshes before=", before, " after=", _meshes(kit), " merged groups=", materials)
		get_root().remove_child(kit)
		kit.free()
	quit()
