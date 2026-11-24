extends SceneTree
var t0 := 0
func _init():
	t0 = Time.get_ticks_msec()
	var cb = load("res://scripts/world/city_builder.gd").new()
	get_root().add_child(cb)
	print("builder ok ms=", Time.get_ticks_msec() - t0)
	quit()
