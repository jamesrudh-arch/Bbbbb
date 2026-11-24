extends Node
## Find the 13 orphan Node3Ds by keeping a registry of every Node3D the world
## creates, then comparing after teardown.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	print("F orphans after build=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	# the 13 appear only after teardown; snapshot by id what is detached NOW
	w.queue_free()
	for i in 5:
		await get_tree().process_frame
	print("F orphans after teardown=", int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	# enumerate remaining objects: use ResourceLoader-free ObjectDB ping through
	# instance ids harvested from a full tree walk before the free
	get_tree().quit()
