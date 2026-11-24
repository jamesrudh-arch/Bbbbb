extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	get_root().add_child(kit)
	var p = kit.person(Vector3(0,0,0), 0.0, null, "casual-male")
	print("person node scale=", p.scale)
	for n in p.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		print("  mi=", mi.name, " inst_scale=", mi.scale)
		var xf := mi.global_transform
		print("  aabb=", mi.get_aabb().size, " global_scale_approx=", xf.basis.get_scale())
		for si in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(si)
			var nm := "none"
			var col := "n/a"
			if ov != null and ov is BaseMaterial3D:
				nm = ov.resource_name
				col = str((ov as BaseMaterial3D).albedo_color)
			print("   surf", si, " over=", ov != null, " col=", col)
	# measure real height
	await process_frame
	await process_frame
	var total := AABB()
	var first := true
	for n in p.find_children("*", "MeshInstance3D", true, false):
		var mi2 := n as MeshInstance3D
		var b: AABB = mi2.global_transform * mi2.get_aabb()
		if first: total = b; first = false
		else: total = total.merge(b)
	print("HEIGHT=", total.size.y, " origin_y=", total.position.y)
	quit()
