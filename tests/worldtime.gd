extends Node
var t := 0.0
var t0 := 0
var ready_done := false
func _ready():
	t0 = Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	ready_done = true
	print("READY MS=", Time.get_ticks_msec() - t0)
	var desc := 0
	for id in w.districts:
		desc += _count(w.districts[id])
	print("DISTRICT_DESCENDANTS=", desc)
	print("PEDS=", w.npcs.pedestrians.size(), " NAMED=", w.npcs.named.size())
	get_tree().quit()
func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _count(ch)
	return c
