extends Node
## Multi-angle street harness. Renders several cameras in one run so a street
## can be judged from the angles a player actually sees, instead of iterating
## one shot at a time. SHOTS="name:x,y,z:lx,ly,lz;..."  (semicolon separated)
var t := 0.0
var idx := 0
var done := false
var shots: Array = []
var prefix := "/home/user/s"
var cams: Array = []

func _ready():
	var st := OS.get_environment("STREET_TYPE")
	var stype := int(st) if st != "" else 0
	var pp := OS.get_environment("SHOT_PREFIX")
	if pp != "": prefix = pp
	var spec := OS.get_environment("SHOTS")
	if spec == "":
		# default: the player camera down-street, plus a 3/4 across-street view
		spec = "down:-26,2.35,-4.6|16,2.2,-3.2;aerial:-30,11,20|-4,1.5,4"
	for chunk in spec.split(";"):
		var parts: PackedStringArray = chunk.split("|")
		var head: PackedStringArray = parts[0].split(":")
		var p: PackedStringArray = head[1].split(",")
		var l: PackedStringArray = parts[1].split(",")
		shots.append([head[0], Vector3(float(p[0]), float(p[1]), float(p[2])),
			Vector3(float(l[0]), float(l[1]), float(l[2]))])

	var env := WorldEnvironment.new()
	var e2 := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.16, 0.32, 0.66)
	sm.sky_horizon_color = Color(0.80, 0.72, 0.60)
	sm.ground_bottom_color = Color(0.12, 0.11, 0.10)
	sm.ground_horizon_color = Color(0.66, 0.60, 0.50)
	sky.sky_material = sm
	e2.sky = sky
	e2.background_mode = Environment.BG_SKY
	e2.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e2.ambient_light_sky_contribution = 1.0
	e2.ambient_light_energy = 0.95
	e2.tonemap_mode = Environment.TONE_MAPPER_ACES
	e2.tonemap_white = 4.0
	e2.glow_enabled = true
	e2.glow_intensity = 0.45
	e2.glow_bloom = 0.10
	e2.ssao_enabled = true
	e2.ssao_intensity = 1.2
	e2.ssao_radius = 1.4
	e2.fog_enabled = true
	e2.fog_light_color = Color(0.72, 0.68, 0.62)
	e2.fog_density = 0.0035
	e2.fog_sky_affect = 0.2
	env.environment = e2
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 48, 0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 2.3
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 110.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.6
	sun.shadow_blur = 1.6
	sun.light_angular_distance = 1.6
	add_child(sun)

	var g := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(600, 1, 600)
	cs.shape = bs; g.add_child(cs); g.position = Vector3(0, -0.5, 0)
	add_child(g)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(600, 600)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.28, 0.26, 0.23); fm.roughness = 0.96
	floor_mi.material_override = fm
	add_child(floor_mi)

	var kit = load("res://scripts/world/street_kit.gd").new()
	kit.set_seed(20261123)
	add_child(kit)
	var len_s := 110.0
	var origin := Vector3(-55, 0, 0)
	var os_env := OS.get_environment("STREET_ORIGIN")
	if os_env != "":
		var oa: PackedStringArray = os_env.split(",")
		origin = Vector3(float(oa[0]), float(oa[1]), float(oa[2]))
	kit.chassis(origin, Vector3(1, 0, 0), len_s, stype)
	for side in [-1.0, 1.0]:
		kit.shophouse_row(origin, Vector3(1, 0, 0), len_s, side, stype)
	kit.populate_street(origin, Vector3(1,0,0), len_s, stype)
	kit.power_lines(origin, Vector3(1,0,0), len_s, stype)
	kit.populate_people(origin, Vector3(1,0,0), len_s, stype)

	for s2 in shots:
		var c := Camera3D.new()
		c.position = s2[1]
		add_child(c)
		c.look_at(s2[2], Vector3.UP)
		c.fov = 68.0
		c.far = 500.0
		cams.append(c)
	cams[0].current = true
	print("SHOT ready ", shots.size(), " cams")

func _process(d):
	t += d
	if t > 3.0 + idx * 1.1 and not done:
		if idx < cams.size():
			var img := get_viewport().get_texture().get_image()
			if img:
				var path: String = prefix + "_" + str(shots[idx][0]) + ".png"
				img.save_png(path)
				print("SHOT ", path)
			idx += 1
			if idx < cams.size(): cams[idx].current = true
			if idx >= cams.size(): done = true
	if done and t > 3.0 + idx * 1.1 + 1.0:
		get_tree().quit()
