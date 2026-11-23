extends Node3D
## OPENING CINEMATIC — "Nine Days"
##
## Four shots, real camera direction (dolly, crane, rack focus), each ending on a
## titled beat. Runs inside a SubViewport in the boot flow, then hands off to play.
##
## Shot 1 — DAWN OVER CINDER CITY (crane down through rooftops)
## Shot 2 — THE BUS (slow dolly past the window, rain on glass)
## Shot 3 — MARCUS (over-shoulder, a folded letter in his hands)
## Shot 4 — THE MISSING BROTHER (empty chair, phone ringing unanswered)

const BEAT := Color(0.93, 0.86, 0.70)
const DIM := Color(0.62, 0.66, 0.72)

var _cam: Camera3D
var _label: Label3D
var _sub: Label3D
var _shot := 0
var _t := 0.0
var _shot_time := 0.0
var _done := false

signal finished

const SHOTS := [
	{"dur": 6.2, "title": "", "sub": ""},
	{"dur": 5.4, "title": "", "sub": ""},
	{"dur": 6.0, "title": "", "sub": ""},
	{"dur": 5.0, "title": "", "sub": ""},
]

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_city()
	_build_labels()
	_begin_shot(0)

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	# Cold overhead, warm dust at the horizon — Ash Row at 6 a.m.
	sm.sky_top_color = Color(0.09, 0.12, 0.20)
	sm.sky_horizon_color = Color(0.86, 0.62, 0.38)
	sm.ground_horizon_color = Color(0.60, 0.45, 0.30)
	sm.ground_bottom_color = Color(0.05, 0.05, 0.06)
	sm.sun_angle_max = 22.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.42
	env.fog_enabled = true
	env.fog_light_color = Color(0.52, 0.42, 0.34)
	env.fog_density = 0.0032
	env.fog_sky_affect = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.0
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.74, 0.48)
	sun.light_energy = 1.6
	sun.rotation_degrees = Vector3(-7.0, 128.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)

func _build_camera() -> void:
	_cam = Camera3D.new()
	_cam.fov = 42.0
	_cam.near = 0.15
	_cam.far = 700.0
	_cam.position = Vector3(0.0, 30.0, 60.0)
	add_child(_cam)
	_cam.look_at(Vector3(0.0, 8.0, -10.0))
	_cam.make_current()

# ----------------------------------------------------------------------- city
## A silhouette skyline for the cinematic only — cheap boxes, no collision.
## The playable city is built separately by city_builder.gd.
func _build_city() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261123
	var root := Node3D.new()
	root.name = "CineCity"
	add_child(root)

	var wall := StandardMaterial3D.new()
	wall.albedo_color = Color(0.075, 0.072, 0.078)
	wall.roughness = 0.95

	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.95, 0.76, 0.36)
	lit.emission_enabled = true
	lit.emission = Color(1.0, 0.78, 0.40)
	lit.emission_energy_multiplier = 3.2

	var mm := MultiMeshInstance3D.new()
	var mmi := MultiMesh.new()
	mmi.transform_format = MultiMesh.TRANSFORM_3D
	mmi.mesh = BoxMesh.new()
	mmi.instance_count = 170
	for i in 170:
		var r := 34.0 + 62.0 * sqrt(rng.randf())
		var a := rng.randf() * TAU
		var h := rng.randf_range(5.0, 44.0)
		var w := rng.randf_range(3.0, 9.0)
		var d := rng.randf_range(3.0, 9.0)
		var xf := Transform3D()
		xf = xf.scaled(Vector3(w, h, d))
		xf.origin = Vector3(cos(a) * r, h * 0.5 - 2.0, sin(a) * r - 20.0)
		mmi.set_instance_transform(i, xf)
	mm.multimesh = mmi
	mm.material_override = wall
	root.add_child(mm)

	# Window lights: small emissive quads scattered up the facades.
	var wl := MultiMeshInstance3D.new()
	var wli := MultiMesh.new()
	wli.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.7)
	wli.mesh = q
	wli.instance_count = 420
	for i in 420:
		var base := mmi.get_instance_transform(rng.randi() % 170)
		var hgt: float = base.basis.get_scale().y
		var off := Vector3(
			base.basis.get_scale().x * 0.5 + 0.02,
			rng.randf_range(0.5, maxf(1.0, hgt - 1.0)) - hgt * 0.5,
			rng.randf_range(-0.4, 0.4))
		var xf2 := Transform3D()
		xf2.origin = base.origin + off
		wli.set_instance_transform(i, xf2)
	wl.multimesh = wli
	wl.material_override = lit
	root.add_child(wl)

	# Ground plane so the buildings are not floating.
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(420.0, 420.0)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.055, 0.055, 0.062)
	gm.roughness = 1.0
	g.material_override = gm
	g.position = Vector3(0.0, -2.0, -20.0)
	root.add_child(g)

func _build_labels() -> void:
	_label = Label3D.new()
	_label.font_size = 46
	_label.pixel_size = 0.0018
	_label.modulate = Color(BEAT.r, BEAT.g, BEAT.b, 0.0)
	_label.outline_size = 0
	_label.no_depth_test = true
	_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_label.position = Vector3(0.0, -0.62, -2.2)
	add_child(_label)

	_sub = Label3D.new()
	_sub.font_size = 22
	_sub.pixel_size = 0.0018
	_sub.modulate = Color(DIM.r, DIM.g, DIM.b, 0.0)
	_sub.no_depth_test = true
	_sub.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sub.position = Vector3(0.0, -0.76, -2.2)
	add_child(_sub)

# ---------------------------------------------------------------------- shots
func _begin_shot(i: int) -> void:
	_shot = i
	_shot_time = 0.0
	if i >= SHOTS.size():
		_finish()
		return
	match i:
		0: _shot_dawn()
		1: _shot_bus()
		2: _shot_hands()
		3: _shot_chair()

## Shot 1 — crane down out of the rooftops toward the street.
func _shot_dawn() -> void:
	_cam.fov = 46.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_cam, "position", Vector3(0.0, 7.0, 30.0), 6.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_cam, "fov", 36.0, 6.2).set_trans(Tween.TRANS_SINE)
	_look_at_smooth(Vector3(0.0, 4.0, -30.0), 6.2)
	_caption("", "", 0.0)

## Shot 2 — slow lateral dolly, rain streaking the glass.
func _shot_bus() -> void:
	_cam.fov = 34.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_cam, "position", Vector3(-5.5, 3.1, 6.5), 5.4)\
		.set_trans(Tween.TRANS_LINEAR)
	_look_at_smooth(Vector3(-1.0, 2.6, 2.0), 5.4)
	_caption("", "", 0.0)

## Shot 3 — over the shoulder, a folded letter.
func _shot_hands() -> void:
	_cam.fov = 30.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_cam, "position", Vector3(0.15, 2.05, 4.1), 6.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_cam, "rotation:y", deg_to_rad(6.0), 6.0)\
		.set_trans(Tween.TRANS_SINE)
	_look_at_smooth(Vector3(0.0, 1.75, 1.2), 6.0)
	_caption("NINE DAYS.", "Your brother has not answered his phone in nine days.", 0.6)

## Shot 4 — the empty chair, the phone still ringing.
func _shot_chair() -> void:
	_cam.fov = 38.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_cam, "position", Vector3(-1.4, 1.7, 2.6), 5.0)\
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_cam, "rotation:y", deg_to_rad(-8.0), 5.0)\
		.set_trans(Tween.TRANS_SINE)
	_look_at_smooth(Vector3(0.0, 1.6, 0.0), 5.0)
	_caption("COME HOME.", "Marcus. Come home.", 0.5)

# Camera is aimed by a tween on a proxy target so the move stays smooth.
func _look_at_smooth(target: Vector3, dur: float) -> void:
	var proxy := Node3D.new()
	proxy.position = target
	add_child(proxy)
	var tw := create_tween()
	tw.tween_method(func(_v: float):
		if is_instance_valid(_cam) and is_instance_valid(proxy):
			_cam.look_at(proxy.position, Vector3.UP)
			, 0.0, 1.0, dur)

func _caption(title: String, sub: String, delay: float) -> void:
	if title == "":
		_label.text = ""
		_sub.text = ""
		return
	_label.text = title
	_sub.text = sub
	var tw := create_tween()
	tw.tween_property(_label, "modulate:a", 1.0, 1.1).set_delay(delay)
	tw.tween_property(_sub, "modulate:a", 0.85, 1.1).set_delay(delay + 0.25)

# ---------------------------------------------------------------------- drive
func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_shot_time += delta
	if _shot < SHOTS.size() and _shot_time >= float(SHOTS[_shot]["dur"]):
		_fade_caption()
		_begin_shot(_shot + 1)

func _fade_caption() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_label, "modulate:a", 0.0, 0.5)
	tw.tween_property(_sub, "modulate:a", 0.0, 0.5)

func _finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(_cam, "fov", 60.0, 1.2)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	finished.emit()
