extends Node
## What exactly are the 4,144 orphan nodes? Name them by walking every live node
## the builder produced and finding which are detached.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	var before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("O orphans with world=", before)
	# count nodes under each kit
	for n in w.find_children("*", "Node3D", true, false):
		if str(n.name) == "StreetKit":
			var sources := 0
			for c in n.get_children():
				if str(c.name) == "StreetSource": sources += 1
			print("O kit sources still parented=", sources)
	# now count what a kit holds in its library
	for n in w.districts.values():
		pass
	var total := 0
	for id in w.districts:
		var d = w.districts[id]
		for n in d.find_children("*", "Node3D", true, false):
			pass
	print("O done")
	get_tree().quit()
