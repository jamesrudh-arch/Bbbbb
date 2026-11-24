extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var w = load("res://scenes/world.tscn").instantiate()
	w.set_script(null)
	add_child(w)
	await get_tree().process_frame
	var cb = load("res://scripts/world/city_builder.gd").new()
	w.add_child(cb)
	var d = cb.build_district("ash_row")
	w.add_child(d)
	await get_tree().process_frame
	print("E orphans built=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("E freeing district...")
	d.free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("E orphans after district free=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	get_tree().quit()
