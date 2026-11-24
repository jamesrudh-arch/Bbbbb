extends SceneTree
func _init():
	var kit = load("res://scripts/world/street_kit.gd").new()
	kit.set_seed(20261123)
	get_root().add_child(kit)
	kit.chassis(Vector3(-55,0,0), Vector3(1,0,0), 110.0, 0)
	for side in [-1.0, 1.0]:
		kit.shophouse_row(Vector3(-55,0,0), Vector3(1,0,0), 110.0, side, 0)
	var rows: Array = kit.get_children()
	var hs := []
	for c in rows:
		if c.name.begins_with("Row"):
			var xs := []
			for b in c.get_children():
				xs.append(snappedf(b.position.x, 0.1))
			xs.sort()
			print("row side children=", c.get_child_count(), " x from ", xs[0], " to ", xs[xs.size()-1])
			hs.append(xs)
	print("total rows=", hs.size())
	var kit2 = load("res://scripts/world/street_kit.gd").new()
	kit2.set_seed(20261123); get_root().add_child(kit2)
	var r = kit2.populate_street(Vector3(-55,0,0), Vector3(1,0,0), 110.0, 0)
	var zs := {}
	for c in r.get_children():
		var key: String = c.name.rstrip("0123456789")
		zs[key] = zs.get(key, 0) + 1
	print("props ", zs)
	quit()
