extends SceneTree
var w
var phase := 0
var t0 := 0
func _initialize():
	t0 = Time.get_ticks_msec()
	w = load("res://scenes/world.tscn").instantiate()
	print("P instantiate ms=", Time.get_ticks_msec() - t0)
	t0 = Time.get_ticks_msec()
	get_root().add_child(w)
	print("P add_child ms=", Time.get_ticks_msec() - t0, " nodes=", _c(get_root()))
	quit()
func _c(n: Node) -> int:
	var c := 1
	for ch in n.get_children(): c += _c(ch)
	return c
