extends Node
## Places a person on an open street, then frames them from a fixed offset, so
## the figure can be judged without hunting for camera coordinates.
var t := 0.0
var done := false
func _ready():
	var env := WorldEnvironment.new()
	var en := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.16, 0.32, 0.66)
	sm.sky_horizon_color = Color(0.82, 0.74, 0.60)
	sm.ground_horizon_color = Color(0.66, 0.60, 0.50)
	sm.ground_bottom_color = Color(0.12, 0.11, 0.10)
	sky.sky_material = sm
	en.sky = sky
	en.background_mode = Environment.BG_SKY
	en.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	en.ambient_light_energy = 1.0
	en.tonemap_mode = Environment.TONE_MAPPER_ACES
	en.tonemap_white = 4.0
	env.environment = en
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color(1.0, 0.88, 0.70)
	sun.light_energy = 2.4
	sun.shadow_enabled = true
	add_child(sun)
	# plain ground, nothing overhead: the point is the figure, not the street
	var f := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	f.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.42, 0.40, 0.38); fm.roughness = 0.95
	f.material_override = fm
	add_child(f)

	var kit = load("res://scripts/world/street_kit.gd").new()
	kit.set_seed(7)
	add_child(kit)
	# a row of figures at even spacing, so several skins/clothes are visible
	var names := ["casual-male", "casual-female", "worker-male", "casual2-female", "casual3-male"]
	for i in 5:
		kit.person(Vector3(i * 1.15 - 2.3, 0, 0), PI, null, names[i], 1.0)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.35, 4.6)
	cam.look_at(Vector3(0, 1.05, 0))
	cam.fov = 48.0
	add_child(cam)
	cam.current = true
	print("PERSONSHOT READY")
func _process(d):
	t += d
	if t > 2.5 and not done:
		done = true
		var img := get_viewport().get_texture().get_image()
		if img: img.save_png("/home/user/people.png"); print("SHOT /home/user/people.png")
		get_tree().quit()
