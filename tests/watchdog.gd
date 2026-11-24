extends SceneTree
## Does the tree reach its first frame at all?
var frames := 0
func _initialize():
	var w = load("res://scenes/world.tscn").instantiate()
	get_root().add_child(w)
	print("W added, nodes will build next frame")
	# kick a deferred job so we can see if idle processing ever runs
	(Engine.get_main_loop() as SceneTree).process_frame.connect(func(): print("SIG process_frame"))
func _process(_d: float) -> bool:
	frames += 1
	print("W frame ", frames)
	return frames >= 2
