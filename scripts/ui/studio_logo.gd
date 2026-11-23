extends Node3D
## D'YOUNGS GAMES — real 3D studio mark.
##
## The D·Y monogram is extruded TextMesh geometry with a metallic gold PBR
## material, not a flat image. Ash particles converge inward from a sphere onto
## the mark, a warm key light and a gold rim light shape it, then a specular
## sweep travels across the metal and the studio name typesets beneath.

const GOLD := Color(0.92, 0.74, 0.38)
const GOLD_DEEP := Color(0.55, 0.38, 0.12)

var _mark: MeshInstance3D
var _mark_mat: StandardMaterial3D
var _name_label: Label3D
var _sweep: OmniLight3D
var _ash: GPUParticles3D
var _ash_mat: StandardMaterial3D
var _t := 0.0
var _done := false

signal finished

func _ready() -> void:
	_build_environment()
	_build_lights()
	_build_mark()
	_build_ash()
	_build_name()
	_animate()

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.014, 0.016, 0.021)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.15, 0.15)
	env.ambient_light_energy = 0.55
	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.92
	we.environment = env
	add_child(we)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.04, 4.15)
	cam.fov = 38.0
	cam.look_at(Vector3(0.0, -0.02, 0.0))
	add_child(cam)

# --------------------------------------------------------------------- lights
func _build_lights() -> void:
	# Key: warm, high and to the left, gives the metal its body.
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.88, 0.72)
	key.light_energy = 0.95
	key.rotation_degrees = Vector3(-38.0, -52.0, 0.0)
	add_child(key)

	# Rim: gold from behind, separates the mark from the black.
	var rim := OmniLight3D.new()
	rim.light_color = GOLD
	rim.light_energy = 1.9
	rim.omni_range = 4.0
	rim.position = Vector3(0.4, 0.5, -2.1)
	add_child(rim)

	# Sweep: travels left to right across the face, catching the bevel.
	_sweep = OmniLight3D.new()
	_sweep.light_color = Color(1.0, 0.94, 0.80)
	_sweep.light_energy = 0.0
	_sweep.omni_range = 2.6
	_sweep.position = Vector3(-3.0, 0.35, 1.9)
	add_child(_sweep)

# ----------------------------------------------------------------------- mark
func _build_mark() -> void:
	_mark = MeshInstance3D.new()
	var tm := TextMesh.new()
	tm.text = "D·Y"
	tm.font_size = 128
	tm.depth = 0.11        # extrusion, not a tunnel
	tm.pixel_size = 0.0112
	tm.curve_step = 1.2
	tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mark.mesh = tm

	_mark_mat = StandardMaterial3D.new()
	_mark_mat.albedo_color = Color(0.42, 0.37, 0.28)
	_mark_mat.metallic = 0.93
	_mark_mat.roughness = 0.30
	_mark_mat.metallic_specular = 0.85
	_mark_mat.emission_enabled = true
	_mark_mat.emission = GOLD_DEEP
	_mark_mat.emission_energy_multiplier = 0.0
	_mark.material_override = _mark_mat

	# Starts crushed and dark; the animation opens it up.
	_mark.scale = Vector3(0.86, 0.86, 0.86)
	_mark.position = Vector3(0.0, 0.10, 0.0)
	add_child(_mark)

# ------------------------------------------------------------------------ ash
func _build_ash() -> void:
	_ash = GPUParticles3D.new()
	_ash.amount = 320
	_ash.lifetime = 2.6
	_ash.preprocess = 0.4
	add_child(_ash)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 2.2
	# Negative radial acceleration pulls the grains inward onto the mark.
	pm.radial_accel_min = -2.9
	pm.radial_accel_max = -1.5
	pm.gravity = Vector3(0.0, -0.16, 0.0)
	pm.initial_velocity_min = 0.04
	pm.initial_velocity_max = 0.30
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	pm.color = Color(0.98, 0.80, 0.48, 0.9)
	_ash.process_material = pm

	var quad := QuadMesh.new()
	quad.size = Vector2(0.0085, 0.0085)
	_ash_mat = StandardMaterial3D.new()
	_ash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_ash_mat.albedo_color = Color(1.0, 0.84, 0.52)
	_ash_mat.emission_enabled = true
	_ash_mat.emission = Color(1.0, 0.74, 0.34)
	_ash_mat.emission_energy_multiplier = 1.4
	_ash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = _ash_mat
	_ash.draw_pass_1 = quad

# ----------------------------------------------------------------------- name
func _build_name() -> void:
	_name_label = Label3D.new()
	_name_label.text = "D'YOUNGS GAMES"
	_name_label.font_size = 34
	_name_label.pixel_size = 0.0042
	_name_label.modulate = Color(0.94, 0.90, 0.82, 0.0)
	_name_label.outline_size = 0
	_name_label.position = Vector3(0.0, -0.86, 0.16)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_name_label.no_depth_test = true
	add_child(_name_label)

# -------------------------------------------------------------------- animate
func _animate() -> void:
	var tw := create_tween()
	tw.set_parallel(true)

	# 1. Mark settles out of the dark.
	tw.tween_property(_mark, "scale", Vector3.ONE, 1.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mark, "position:y", 0.0, 1.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mark_mat, "emission_energy_multiplier", 0.30, 1.6)\
		.set_delay(0.35)
	tw.tween_property(_mark_mat, "albedo_color", Color(0.66, 0.56, 0.40), 1.5)\
		.set_delay(0.2)

	# 2. Specular sweep across the face.
	tw.tween_property(_sweep, "light_energy", 3.4, 0.18).set_delay(1.28)
	tw.tween_property(_sweep, "position:x", 3.0, 0.85)\
		.set_delay(1.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_sweep, "light_energy", 0.0, 0.35).set_delay(2.16)

	# 3. Studio name typesets beneath.
	tw.tween_property(_name_label, "modulate:a", 1.0, 0.75).set_delay(2.30)
	tw.tween_property(_name_label, "position:y", -0.82, 0.75)\
		.set_delay(2.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 4. Ash thins out as the mark resolves.
	tw.tween_property(_ash, "amount_ratio", 0.22, 1.4).set_delay(2.1)
	await tw.finished
	await get_tree().create_timer(0.55).timeout
	finished.emit()
