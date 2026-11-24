extends Node
## Renders one district's streets (4 assembled streets = a city block's worth)
## so the "combined into a city" result can actually be inspected.
var t := 0.0
var done := false
func _ready():
	var e := WorldEnvironment.new()
	var en := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.16, 0.32, 0.66)
	sm.sky_horizon_color = Color(0.84, 0.76, 0.62)
	sm.ground_horizon_color = Color(0.68, 0.62, 0.52)
	sm.ground_bottom_color = Color(0.12, 0.11, 0.10)
	sky.sky_material = sm
	en.sky = sky
	en.background_mode = Environment.BG_SKY
	en.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	en.ambient_light_energy = 0.95
	en.tonemap_mode = Environment.TONE_MAPPER_ACES
	en.tonemap_white = 4.0
	en.glow_enabled = true
	en.glow_intensity = 0.4
	en.fog_enabled = true
	en.fog_light_color = Color(0.76, 0.72, 0.66)
	en.fog_density = 0.0035
	en.fog_sky_affect = 0.35
	e.environment = en
	add_child(e)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, 46, 0)
	sun.light_color = Color(1.0, 0.87, 0.68)
	sun.light_energy = 2.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.6
	add_child(sun)

	var kit = load("res://scripts/world/street_kit.gd").new()
	kit.set_seed(424242)
	add_child(kit)
	# a district: two parallel streets and one crossing street
	# Same layout the city uses, so this shot reflects the real result.
	var pitch := 76.0
	var span := pitch * 2.0 + 8.0
	var mid := pitch * 0.5
	var v := 0
	for z in [-mid, mid]:
		var s: Node3D = kit.get_street(0, v, span)
		s.position = Vector3(-span * 0.5, 0.0, z)
		add_child(s)
		v += 1
	for x in [-mid, mid]:
		var sx: Node3D = kit.get_street(0, v, span)
		sx.position = Vector3(x, 0.0, -span * 0.5)
		sx.rotation.y = PI * 0.5
		add_child(sx)
		v += 1

	var cam := Camera3D.new()
	var cs := OS.get_environment("DCAM")
	if cs == "":
		cs = "-30,2.6,-46|14,4.0,-30"
	var parts: PackedStringArray = cs.split("|")
	var p1: PackedStringArray = parts[0].split(",")
	var p2: PackedStringArray = parts[1].split(",")
	cam.position = Vector3(float(p1[0]), float(p1[1]), float(p1[2]))
	cam.look_at(Vector3(float(p2[0]), float(p2[1]), float(p2[2])), Vector3.UP)
	cam.fov = 66.0
	# Never shoot from inside a building: if the requested camera is embedded,
	# walk it up and back until it is free. Guessing coordinates has cost more
	# time on this project than any other single thing.
	add_child(cam)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_viewport().world_3d.direct_space_state
	var p := cam.position
	var fixed := false
	for i in range(40):
		var pq := PhysicsPointQueryParameters3D.new()
		pq.position = p
		pq.collision_mask = 1
		if space.intersect_point(pq).is_empty():
			fixed = true
			break
		p += Vector3(0, 1.5, 0)
	if fixed:
		cam.position = p
		cam.look_at(Vector3(float(p2[0]), float(p2[1]), float(p2[2])), Vector3.UP)
		print("CAM fixed at ", p)
	else:
		print("CAM could not clear")
	cam.far = 400.0
	add_child(cam)
	cam.current = true
	print("DISTRICT READY")
func _process(d):
	t += d
	if t > 5.0 and not done:
		done = true
		var img := get_viewport().get_texture().get_image()
		if img: img.save_png("/home/user/district.png"); print("SHOT /home/user/district.png")
		get_tree().quit()
