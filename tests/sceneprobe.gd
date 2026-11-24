extends Node
var t := 0.0
func _ready():
	var t0 := Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	print("WORLD INSTANTIATED ms=", Time.get_ticks_msec() - t0)
func _process(d):
	t += d
	if t > 3.0:
		var n := _count(get_tree().root)
		print("NODES=", n, " fps=", Engine.get_frames_per_second())
		var w = get_child(0)
		print("PLAYER=", w.player.global_position if w.player else "none")
		var bodies := 0
		var stack: Array = [get_tree().root]
		while stack.size() > 0:
			var x: Node = stack.pop_back()
			for ch in x.get_children(): stack.append(ch)
			if x is StaticBody3D: bodies += 1
		print("STATIC BODIES=", bodies)
		var dmap: Dictionary = w.districts
		for id in dmap:
			var dn: Node3D = dmap[id]
			print("  district ", id, " children=", dn.get_child_count(), " visible=", dn.visible)
		get_tree().quit()
func _count(x: Node) -> int:
	var c := 1
	for ch in x.get_children():
		c += _count(ch)
	return c
