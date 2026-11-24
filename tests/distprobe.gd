extends SceneTree
## DISTPROBE — build exactly ONE district and report its cost, then quit.
##
## Why this exists: the full six-district world (~30k nodes) peaks the CI
## sandbox's memory and the process is OOM-killed partway through the build,
## which looks exactly like a genuine engine incompatibility. Building one
## district per process keeps peak memory low and turns "it died" into
## "district X = N nodes in M ms", so a Godot 4.4 (Xogot) run can be compared
## against a Godot 4.7.2 (authoring) run district by district.
##
## Autoloads (Content, etc.) do not exist under --script, so the probe boots
## through world.tscn with its script stripped, exactly like readyprobe.gd.
##
##   DIST=neon_mile godot --headless --script res://tests/distprobe.gd
##   DIST=all      every district, freed between builds

func _initialize() -> void:
	var w = load("res://scenes/world.tscn").instantiate()
	w.set_script(null)
	var cb = load("res://scripts/world/city_builder.gd").new()
	w.add_child(cb)
	var want := OS.get_environment("DIST")
	var ids: Array = ["ash_row", "guttermarket", "iron_yard", "cinder_line",
		"vesper_heights", "neon_mile"]
	if want != "" and want != "all":
		ids = [want]
	for id in ids:
		var t := Time.get_ticks_msec()
		var d = cb.build_district(id)
		var ms := Time.get_ticks_msec() - t
		print("D %s nodes=%d ms=%d" % [id, _count(d), ms])
		if OS.get_environment("CENSUS") != "":
			_census(d)
		d.free()
	print("D done")
	quit()

func _census(root: Node) -> void:
	var kinds := {}
	for n in root.find_children("*", "", true, false):
		var k := n.get_class()
		kinds[k] = int(kinds.get(k, 0)) + 1
	var keys := kinds.keys()
	keys.sort()
	for k in keys:
		print("   ", k, " ", kinds[k])

func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count(ch)
	return c
