extends SceneTree
func _init():
	var t0 := Time.get_ticks_msec()
	var w = load("res://scenes/world.tscn")
	print("load tscn ms=", Time.get_ticks_msec() - t0)
	quit()
