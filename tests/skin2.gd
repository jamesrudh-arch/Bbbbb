extends Node
func _ready():
	# same as street use: parented under a rotated Node3D, tinted, grounded,
	# and duplicated from a cached PackedScene - inside a district tree
	var kit = load("res://scripts/world/street_kit.gd").new()
	add_child(kit)
	var holder := Node3D.new()
	holder.rotation.y = 1.234
	add_child(holder)
	for i in 36:
		kit.person(Vector3(i * 2.0, 0.02, 7.0), i, holder, "", 1.0)
	print("S2 spawned")
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while frames < 2 and Time.get_ticks_msec() - t0 < 40000:
		await get_tree().process_frame
		frames += 1
	print("S2 frames=", frames, " ms=", Time.get_ticks_msec() - t0)
	get_tree().quit()
