extends Node
var t := 0.0
func _ready():
	var t0 := Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	print("WORLD INSTANTIATED ms=", Time.get_ticks_msec() - t0)
func _process(d):
	t += d
	if t > 2.0:
		var n := _count(get_tree().root)
		print("NODES=", n, " fps=", Engine.get_frames_per_second())
		get_tree().quit()
func _count(x: Node) -> int:
	var c := 1
	for ch in x.get_children():
		c += _count(ch)
	return c
