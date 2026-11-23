extends Node3D
## Renders the interactive map so its layout can be verified visually.
func _ready():
	var w = load("res://scenes/world.tscn").instantiate()
	add_child(w)
	for i in 20: await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	var hud = w.hud
	hud.toggle_map()
	await get_tree().process_frame
	var m = hud._mapview.get_node_or_null("WorldMap")
	if m == null:
		print("[MAP] FAILED to create map view"); get_tree().quit(); return
	# Set a destination so the route draws.
	m._set_destination("_district:iron_yard")
	m._build_route()
	for i in 12: await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	print("[MAP] dest=", m.destination_name(), " route_pts=", m._route.size(), " len=", "%.0f" % m._route_len)
	var img := get_viewport().get_texture().get_image()
	img.save_png("/home/user/leverage/shots/map_01.png")
	print("SHOT_SAVED")
	get_tree().quit()
