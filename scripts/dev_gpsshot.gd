extends Node3D
## Verifies the minimap and the on-road GPS ribbon together.
func _ready():
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	for i in 25: await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	# Force a destination so there is a live route to draw.
	print("[G] hud=", w.hud != null)
	if w.hud._mapview == null:
		print("[G] opening map")
		w.hud.toggle_map()
		for i in 5: await get_tree().process_frame
		print("[G] map opened")
	print("[G] mapview=", w.hud._mapview)
	var m = w.hud._mapview.get_node_or_null("WorldMap") if w.hud._mapview != null else null
	print("[G] mapview=", m != null)
	if m != null:
		m._set_destination("mama_ngozi")
	await get_tree().create_timer(1.4).timeout
	# Close the full map so the gameplay HUD (minimap) is visible.
	w.hud.toggle_map()
	for i in 8: await get_tree().process_frame
	print("[G] route pts=", w.hud.map_route().size())
	print("[G] gps_line children=", w.gps_line.get_child_count())
	# Put the camera high so the ribbon on the road is visible.
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		var p: Vector3 = w.player.global_position
		cam.global_position = p + Vector3(-3, 17, 16)
		cam.look_at(p + Vector3(0, 0, -10))
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/user/leverage/shots/gps_01.png")
	print("SHOT_SAVED gps")
	get_tree().quit()
