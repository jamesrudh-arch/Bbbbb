extends VehicleBody3D
## VEHICLE — arcade-leaning physics tuned for touch driving.
## Cars use 4-wheel steering/engine forces. Motorcycles use the same body with
## two-wheel contact + a leaning visual, so both share one control path.

signal exited

@export var vehicle_type := "sedan"
@export var is_police := false

var driver: Node = null
var occupied := false
var ai_controlled := false
var ai_target := Vector3.ZERO
var patrol_center := Vector3.ZERO
var is_player_owned := false

var _ai_speed := 0.0
var engine_sound: AudioStreamPlayer3D
var _horn_cd := 0.0
var _visual: Node3D
var _wheels: Array = []
var _two_wheel := false
var _lean := 0.0


var _configured := false
var _built := false

func _ready() -> void:
	_ensure_built()

func configure(kind: String) -> void:
	vehicle_type = kind
	var cfg: Dictionary = Content.VEHICLE_TYPES.get(kind, Content.VEHICLE_TYPES["sedan"])
	mass = float(cfg["mass"])
	_two_wheel = bool(cfg.get("two_wheel", false))
	_configured = true
	# If we are already in the tree, rebuild with the requested type.
	if is_inside_tree():
		_ensure_built()

func _ensure_built() -> void:
	if _built: return
	_built = true
	var cfg: Dictionary = Content.VEHICLE_TYPES.get(vehicle_type, Content.VEHICLE_TYPES["sedan"])
	mass = float(cfg["mass"])
	_two_wheel = bool(cfg.get("two_wheel", false))
	_setup_body()
	engine_sound = AudioStreamPlayer3D.new()
	engine_sound.volume_db = -60.0
	engine_sound.unit_size = 10.0
	engine_sound.max_distance = 55.0
	add_child(engine_sound)
func _setup_body() -> void:
	# Model
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var model_name: String = Content.VEHICLE_TYPES.get(vehicle_type, Content.VEHICLE_TYPES["sedan"])["model"]
	var path := "res://assets/models/vehicles/%s.glb" % model_name
	var built_model := false
	if ResourceLoader.exists(path):
		var ps := load(path)
		if ps != null:
			var m = ps.instantiate()
			var vs := 1.25
			m.scale = Vector3.ONE * vs
			# Kenney car kit is centre-origin; lift by half-height so tyres touch road.
			m.position.y = 0.33 * vs
			_visual.add_child(m)
			built_model = true
	if not built_model:
		_build_fallback_body()

	# Collision: one box, slammed to the chassis.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	if _two_wheel:
		box.size = Vector3(0.75, 1.0, 2.1)
	else:
		box.size = Vector3(1.75, 1.15, 3.9)
	shape.shape = box          # <- was missing: shape stayed null and the car fell through
	shape.position.y = 0.72
	add_child(shape)

	# Wheels: 4 for cars, 2 for bikes. Front wheels steer.
	var wheel_positions := [
		Vector3(-0.78, 0.34, 1.30), Vector3(0.78, 0.34, 1.30),
		Vector3(-0.78, 0.34, -1.30), Vector3(0.78, 0.34, -1.30),
	]
	if _two_wheel:
		wheel_positions = [Vector3(0, 0.34, 0.92), Vector3(0, 0.34, -0.92)]
	for i in wheel_positions.size():
		var w := VehicleWheel3D.new()
		w.position = wheel_positions[i]
		w.use_as_steering = i < 2
		w.use_as_traction = true
		w.wheel_radius = 0.34
		w.wheel_rest_length = 0.24
		w.suspension_travel = 0.26
		w.suspension_stiffness = 44.0
		w.damping_compression = 1.1
		w.damping_relaxation = 1.5
		w.wheel_friction_slip = 2.8
		add_child(w)
		_wheels.append(w)

	# Lights: cheap emissive quads + one forward spot.
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(1.0, 0.95, 0.8)
	head_mat.emission_enabled = true
	head_mat.emission = Color(1.0, 0.92, 0.72)
	head_mat.emission_energy_multiplier = 3.0
	for sx in [-0.55, 0.55]:
		var hl := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.36, 0.2)
		hl.mesh = q
		hl.material_override = head_mat
		hl.position = Vector3(sx, 0.72, (1.05 if _two_wheel else 1.96))
		_visual.add_child(hl)
	var tail_mat := StandardMaterial3D.new()
	tail_mat.albedo_color = Color(1.0, 0.2, 0.16)
	tail_mat.emission_enabled = true
	tail_mat.emission = Color(1.0, 0.15, 0.1)
	tail_mat.emission_energy_multiplier = 2.0
	for sx in [-0.55, 0.55]:
		var tl := MeshInstance3D.new()
		var tq := QuadMesh.new()
		tq.size = Vector2(0.34, 0.16)
		tl.mesh = tq
		tl.material_override = tail_mat
		tl.position = Vector3(sx, 0.76, (-0.95 if _two_wheel else -1.96))
		tl.rotation.y = PI
		_visual.add_child(tl)
	var spot := SpotLight3D.new()
	spot.light_energy = 2.6
	spot.spot_range = 28.0
	spot.spot_angle = 40.0
	spot.spot_attenuation = 1.2
	spot.position = Vector3(0, 0.9, 1.8)
	spot.rotation_degrees = Vector3(-6, 0, 0)
	add_child(spot)


func _build_fallback_body() -> void:
	if _two_wheel:
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.18, 0.19, 0.22)
		frame_mat.metallic = 0.6
		frame_mat.roughness = 0.35
		var tank_mat := StandardMaterial3D.new()
		tank_mat.albedo_color = Color(0.62, 0.16, 0.20)
		tank_mat.metallic = 0.4
		tank_mat.roughness = 0.28
		_visual.add_child(_prim(Vector3(0.26, 0.3, 1.9), Vector3(0, 0.62, 0.0), frame_mat))
		_visual.add_child(_prim(Vector3(0.46, 0.34, 0.86), Vector3(0, 0.82, 0.28), tank_mat))
		_visual.add_child(_prim(Vector3(0.38, 0.16, 0.78), Vector3(0, 0.80, -0.46), frame_mat))
		_visual.add_child(_prim(Vector3(0.3, 0.2, 0.5), Vector3(0, 0.92, -0.92), tank_mat))
		for sx in [-0.16, 0.16]:
			_visual.add_child(_prim(Vector3(0.08, 0.9, 0.1), Vector3(sx, 0.66, 0.86), frame_mat))
		_visual.add_child(_prim(Vector3(0.72, 0.07, 0.07), Vector3(0, 1.06, 0.8), frame_mat))
		for z in [0.92, -0.92]:
			var wheel := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.33
			cyl.bottom_radius = 0.33
			cyl.height = 0.12
			wheel.mesh = cyl
			wheel.material_override = frame_mat
			wheel.position = Vector3(0, 0.34, z)
			wheel.rotation.z = PI * 0.5
			_visual.add_child(wheel)
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.20, 0.22)
	mat.metallic = 0.35
	mat.roughness = 0.45
	_visual.add_child(_prim(Vector3(1.7, 0.72, 3.7), Vector3(0, 0.68, 0), mat))
	_visual.add_child(_prim(Vector3(1.5, 0.62, 1.9), Vector3(0, 1.28, -0.2), mat))

func _prim(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	return mi
func wheel_contacts() -> int:
	var n := 0
	for w in _wheels:
		if is_instance_valid(w) and w.is_in_contact(): n += 1
	return n

func can_enter() -> bool:
	return driver == null

func occupy(who: Node3D) -> void:
	driver = who
	occupied = true
	ai_controlled = false
	engine_sound.stream = load("res://audio/sfx/engine_loop.wav")
	engine_sound.play()
	engine_sound.volume_db = -12.0

func release() -> void:
	driver = null
	occupied = false
	engine_sound.stop()
	brake = 12.0
	engine_force = 0.0

func exit_point_for(_from: Vector3) -> Vector3:
	var left := global_transform * Vector3(-1.9, 1.2, 0)
	var right := global_transform * Vector3(1.9, 1.2, 0)
	var space := get_world_3d().direct_space_state
	for p in [left, right]:
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.9, 0), p, 1)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return p + Vector3(0, 0.1, 0)
	return global_transform * Vector3(0, 1.4, 3.0)

func _physics_process(delta: float) -> void:
	_horn_cd = maxf(0.0, _horn_cd - delta)
	var cfg: Dictionary = Content.VEHICLE_TYPES.get(vehicle_type, Content.VEHICLE_TYPES["sedan"])
	if occupied and driver != null:
		_drive_player(delta, cfg)
	elif ai_controlled:
		_drive_ai(delta, cfg)
	else:
		engine_force = 0.0
		brake = 8.0
	# Bike lean
	if _two_wheel:
		_lean = lerpf(_lean, -steering * clampf(linear_velocity.length() * 0.06, 0.0, 0.6), delta * 6.0)
		_visual.rotation.z = _lean
	# Engine audio follows speed
	if occupied and engine_sound.playing:
		var spd := linear_velocity.length()
		engine_sound.pitch_scale = clampf(0.7 + spd * 0.045, 0.7, 2.1)
		engine_sound.volume_db = lerpf(-22.0, -6.0, clampf(spd / 20.0, 0.0, 1.0))

func _drive_player(_delta: float, cfg: Dictionary) -> void:
	var throttle := Input.get_action_strength("throttle")
	var brake_in := Input.get_action_strength("brake")
	var steer_in := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var hand := Input.is_action_pressed("handbrake")

	var top := float(cfg["top_speed"])
	var accel := float(cfg["accel"])
	var speed := linear_velocity.length()
	# Engine force must overcome mass + rolling resistance. mass*accel*0.5 gives
	# roughly `accel` m/s^2 of thrust at full throttle for every car type.
	# Only drive when the wheels actually have a contact patch. Applying engine
	# force while airborne accumulates absurd speeds (427 km/h bug).
	var grounded := wheel_contacts() > 0
	if not grounded:
		engine_force = 0.0
		brake = 4.0
	elif speed > top:
		engine_force = 0.0
		brake = 6.0
	else:
		# Taper thrust near top speed instead of a hard cut, so it feels like a car.
		engine_force = throttle * float(cfg["mass"]) * accel * 0.5 * clampf(1.0 - speed / maxf(top, 1.0), 0.12, 1.0)
		brake = brake_in * 24.0
	if hand:
		brake = 30.0
	steering = lerp_angle(steering, -steer_in * 0.52 * float(cfg["handling"]), 0.22)
	# Hard safety clamp: never exceed the type's top speed by more than 15%.
	var vmax := top * 1.15
	if linear_velocity.length() > vmax:
		linear_velocity = linear_velocity.limit_length(vmax)
	if Input.is_action_just_pressed("horn") and _horn_cd <= 0.0:
		_horn_cd = 0.8
		Audio.play_at("horn", global_position, 1.0, 4.0)
	Game.stats["distance_driven"] = float(Game.stats.get("distance_driven", 0.0)) + linear_velocity.length() * _delta

func _drive_ai(_delta: float, cfg: Dictionary) -> void:
	var origin: Vector3 = get_meta("district_origin", patrol_center)
	if ai_target == Vector3.ZERO:
		ai_target = origin + Vector3(randf_range(-30, 30), 0, randf_range(-30, 30))
	var to := ai_target - global_position
	to.y = 0
	if to.length() < 6.0:
		_pick_new_ai_target()
		to = ai_target - global_position
		to.y = 0
	var local := global_transform.basis.inverse() * to.normalized()
	steering = lerp_angle(steering, clampf(-local.x * 1.6, -0.5, 0.5), 0.14)
	var speed := linear_velocity.length()
	var want := float(cfg["top_speed"]) * 0.42
	# Proportional controller: force scales with mass so heavy cars accelerate
	# consistently, and it can never exceed what the drivetrain could produce.
	var err := want - speed
	engine_force = clampf(err * float(cfg["mass"]) * 0.55, 0.0, float(cfg["mass"]) * 1.5)
	brake = 8.0 if err < -1.5 else 0.0
	if speed > want * 1.25:
		engine_force = 0.0
		brake = 14.0
	# Police pursuit overrides target when chasing the player
	if is_police and Game.wanted > 0:
		var p = get_tree().get_first_node_in_group("player")
		if p != null and p.global_position.distance_to(global_position) < 80.0:
			ai_target = p.global_position
			engine_force = clampf((float(cfg["top_speed"]) - speed) * float(cfg["mass"]) * 0.7, 0.0, float(cfg["mass"]) * 1.6)
			if global_position.distance_to(p.global_position) < 2.6 and _horn_cd <= 0.0:
				_horn_cd = 2.0
				Audio.play_at("horn", global_position, 0.8, 3.0)
				if p.combat: p.combat.notify_attacked(self)

func _pick_new_ai_target() -> void:
	var world = get_tree().current_scene
	var origin: Vector3 = get_meta("district_origin", global_position)
	if world != null and world.get("builder") != null:
		var dist: String = world.builder.district_of(origin)
		var nodes: Array = world.builder.drive_graph.get(dist, [])
		var center: Vector3 = world.builder.district_center(dist)
		if not nodes.is_empty():
			ai_target = center + nodes[randi() % nodes.size()]
			return
	ai_target = origin + Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))

func _exit_tree() -> void:
	if driver != null: exited.emit()
