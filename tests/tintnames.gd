extends SceneTree
## What are the real surface names on the figure GLBs? _tint only recolours
## surfaces whose resource_name it recognises; anything else keeps the near-black
## base colour these assets ship with.
func _initialize() -> void:
	var seen := {}
	for m in ["casual-male","casual-female","casual2-male","casual3-male","worker-male","worker-female","casual-bald","suit-male","suit-female","casual2-female","casual3-female"]:
		var p := "res://assets/characters/players/%s.glb" % m
		var ps = load(p)
		if ps == null:
			print("N ", m, " MISSING")
			continue
		var inst = ps.instantiate()
		var names := []
		for n in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null: continue
			for si in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(si) as BaseMaterial3D
				var rn := mat.resource_name if mat != null else "<null mat>"
				names.append(rn)
				if mat != null:
					seen[rn] = mat.albedo_color
		print("N ", m, " surfaces=", names)
		inst.free()
	print("N --- distinct names ---")
	for k in seen:
		print("N   '", k, "' albedo=", seen[k])
	quit()
