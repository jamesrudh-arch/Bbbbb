extends SceneTree
func _initialize():
	var w = load("res://scenes/world.tscn").instantiate()
	w.set_script(null)          # do not run world.gd's _ready at all
	var cb = load("res://scripts/world/city_builder.gd").new()
	w.add_child(cb)
	var t0 := Time.get_ticks_msec()
	for id in ["ash_row", "guttermarket", "iron_yard", "cinder_line", "vesper_heights", "neon_mile"]:
		var t := Time.get_ticks_msec()
		var d = cb.build_district(id)
		print("R ", id, " ms=", Time.get_ticks_msec() - t)
	print("R total ms=", Time.get_ticks_msec() - t0)
	quit()
