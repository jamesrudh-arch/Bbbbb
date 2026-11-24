extends Node
func _ready():
	var mode := OS.get_environment("PROBE")
	if mode == "nostreets":
		Content.set_meta("street_districts", 0)
		print("FP streets DISABLED")
	elif mode.begins_with("d"):
		Content.set_meta("street_districts", int(mode.substr(1)))
		print("FP street districts=", mode.substr(1))
	elif mode == "nopeople":
		OS.set_environment("PART_ENV", "nopeople")
		print("FP people DISABLED")
	var t0 := Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	var root := get_tree().root
	print("FP added nodes=", _c(root), " in ", Time.get_ticks_msec() - t0, "ms")
	var kinds := {}
	var st: Array = [root]
	while st.size() > 0:
		var n2: Node = st.pop_back()
		var k: String = n2.get_class()
		kinds[k] = kinds.get(k, 0) + 1
		for ch in n2.get_children(): st.append(ch)
	print("FP kinds:", kinds)
	var frames := 0
	var t1 := Time.get_ticks_msec()
	while frames < 2 and Time.get_ticks_msec() - t1 < 70000:
		await get_tree().process_frame
		frames += 1
	print("FP frames=", frames, " first2=", Time.get_ticks_msec() - t1, "ms")
	get_tree().quit()
func _c(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _c(ch)
	return c
