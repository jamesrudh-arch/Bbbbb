extends SceneTree
## Runs a real main loop with a hard frame budget, and prints where it goes
## silent. This is the harness that tells us whether the stall is in script
## _process or inside the engine.
var frames := 0
func _initialize():
	var w = load("res://scenes/world.tscn").instantiate()
	get_root().add_child(w)
	print("ST added")
	# Ask the engine to report when each frame ends.
	var tree := self as SceneTree
	var t0 := Time.get_ticks_msec()
	set_meta("t0", t0)
func _idle(_d: float) -> bool:
	frames += 1
	print("ST idle frame ", frames, " at ", Time.get_ticks_msec() - int(get_meta("t0")), "ms")
	return frames >= 3
