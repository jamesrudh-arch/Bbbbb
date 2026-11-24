extends Node
## Count the retained street sources and their descendants: if that matches the
## orphan count, the "leak" is simply the source cache being alive (correct), not
## a bug - and the exit warnings are the cost of caching baked geometry at all.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	# orphan count before any district
	print("O start=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	var w = load("res://scenes/world.tscn").instantiate()
	w.set_script(null)
	add_child(w)
	await get_tree().process_frame
	print("O after bare scene=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	var cb = load("res://scripts/world/city_builder.gd").new()
	w.add_child(cb)
	var d = cb.build_district("ash_row")
	w.add_child(d)
	await get_tree().process_frame
	print("O after 1 district=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	# count sources and their subtrees
	var kits: Array = []
	for n in d.find_children("*", "Node3D", true, false):
		if str(n.name) == "StreetKit": kits.append(n)
	var total := 0
	for k in kits:
		for key in k._library:
			total += _count(k._library[key])
	print("O retained source nodes=", total, " in ", kits.size(), " kit(s)")
	# a second district adds its own
	var d2 = cb.build_district("guttermarket")
	w.add_child(d2)
	await get_tree().process_frame
	print("O after 2 districts=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	get_tree().quit()
func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _count(ch)
	return c
