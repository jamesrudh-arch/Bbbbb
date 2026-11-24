extends SceneTree
func _init():
	var ps = load("res://assets/characters/players/casual-male.glb")
	var inst = ps.instantiate()
	var stack: Array = [inst]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children(): stack.append(ch)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null: continue
			for si in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(si)
				var nm := "null"
				var col := "n/a"
				var tex := "no"
				if m != null:
					nm = m.resource_name
					if m is BaseMaterial3D:
						col = str((m as BaseMaterial3D).albedo_color)
						tex = "yes" if (m as BaseMaterial3D).albedo_texture != null else "no"
				print("surf ", si, " name='", nm, "' col=", col, " tex=", tex)
	inst.free()
	quit()
