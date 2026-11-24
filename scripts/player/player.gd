extends CharacterBody3D
## PLAYER — third-person controller for Emeka Obi.
## Camera-relative movement, sprint/crouch, dodge roll, vehicle hand-off, and
## the bridge points that combat/interaction/driver hang off.

const WALK_SPEED := 2.4
const RUN_SPEED := 5.2
const SPRINT_SPEED := 7.4
const CROUCH_SPEED := 1.4
const ACCEL := 12.0
const FRICTION := 14.0
const JUMP_VELOCITY := 5.2
const GRAVITY := 18.0

@onready var visual: Node3D = $Visual
@onready var model: Node3D = $Visual/Model

@onready var camera_rig: Node3D = $CameraRig
@onready var combat: Node = $Combat
@onready var interaction: Node = $Interaction
@onready var driver: Node = $Driver
@onready var footstep: AudioStreamPlayer3D = $Footstep
@onready var rig: Node3D = $Rig

var move_dir := Vector3.ZERO
var is_sprinting := false
var is_crouching := false
var is_dead := false
var vehicle = null
var can_move := true

var _step_accum := 0.0
var _face_yaw := 0.0
var _model_scale := 1.0

## Game-feel forgiveness (documented in docs/41). Research is unambiguous that
## these two windows are invisible when present and glaring when missing:
##   coyote time  - a jump still works this long after walking off a ledge
##   jump buffer  - a jump pressed this long before landing still fires
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
var _coyote := 0.0
var _jump_buffer := 0.0
var _last_pos := Vector3.ZERO

const SPAWN_POINTS := {
	"apartment": Vector3(-40, 0.35, 34),
	"kitchen": Vector3(-40, 0.35, -6),
	"pawn": Vector3(40, 0.35, 10),
	"garage": Vector3(-40, 0.35, 12),
	"club": Vector3(40, 0.35, -18),
	"foundry": Vector3(-40, 0.35, -30),
}
const SPAWN_YAW := {
	"apartment": 0.0, "kitchen": PI, "pawn": -PI * 0.5,
	"garage": PI * 0.5, "club": 0.0, "foundry": PI,
}
const SPAWN_DISTRICTS := {
	"apartment": "ash_row", "kitchen": "ash_row", "pawn": "guttermarket",
	"garage": "iron_yard", "club": "neon_mile", "foundry": "cinder_line",
}

func _ready() -> void:
	camera_rig.target_node = self
	Game.player_died.connect(_on_died)
	_build_rig()
	_last_pos = global_position
	# Wire the sub-systems once the world (and its interaction system) exists.
	call_deferred("_wire_systems")

func _wire_systems() -> void:
	if combat != null: combat.setup(self)
	if driver != null: driver.setup(self)
	var world = get_parent()
	if interaction != null and world != null and world.get("interactables") != null:
		interaction.setup(self, world.interactables)

func _build_rig() -> void:
	var cid := "emeka"
	var cmodel: String = Content.CHARACTERS[cid]["model"]
	if rig == null: return
	if rig.build(cmodel, 0.92):
		# Hide the placeholder mesh once the real rigged model is live.
		var placeholder := model.get_node_or_null("Mesh")
		if placeholder: placeholder.visible = false
		_model_scale = 1.0

func spawn_at(point_id: String) -> void:
	var local: Vector3 = SPAWN_POINTS.get(point_id, SPAWN_POINTS["apartment"])
	var district: String = SPAWN_DISTRICTS.get(point_id, "ash_row")
	global_position = _district_center(district) + local
	camera_rig.yaw = float(SPAWN_YAW.get(point_id, 0.0))
	camera_rig.target_node = self
	visible = true
	is_dead = false

func _district_center(id: String) -> Vector3:
	var grid: Array = Content.DISTRICTS[id]["grid"]
	return Vector3((float(grid[0]) - 1.0) * 160.0, 0.0, (float(grid[1]) - 0.5) * 160.0)

func _physics_process(delta: float) -> void:
	if is_dead: return
	if vehicle != null:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		# Variable jump height: cut the rise when jump is released early.
		if velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			velocity.y -= GRAVITY * 2.1 * delta

	if not can_move:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
		move_and_slide()
		return

	var input := Vector2.ZERO
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	if input.length() > 1.0: input = input.normalized()
	var basis := Basis(Vector3.UP, camera_rig.yaw)
	move_dir = (basis * Vector3(input.x, 0, input.y)).normalized() if input.length() > 0.05 else Vector3.ZERO

	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and move_dir.length() > 0.1
	var target_speed := 0.0
	if move_dir.length() > 0.05:
		if is_crouching: target_speed = CROUCH_SPEED
		elif is_sprinting: target_speed = SPRINT_SPEED
		elif combat != null and combat.in_combat: target_speed = WALK_SPEED
		else: target_speed = RUN_SPEED
	# Discipline + armour modify top speed
	var stats: Dictionary = Game.discipline_stats()
	var style_speed := float(stats.get("speed", 1.0))
	target_speed *= clampf(lerpf(1.0, style_speed, 0.35), 0.8, 1.15)
	if Game.stamina <= 1.0: target_speed *= 0.62

	var desired := move_dir * target_speed
	velocity.x = move_toward(velocity.x, desired.x, ACCEL * delta * 6.0)
	velocity.z = move_toward(velocity.z, desired.z, ACCEL * delta * 6.0)
	if move_dir.length() < 0.05:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 6.0)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta * 6.0)

	# Coyote time + input buffering.
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(0.0, _coyote - delta)
	if Input.is_action_just_pressed("jump") and not is_crouching:
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0
		Audio.play_at("step_concrete", global_position, randf_range(0.95, 1.05), -14.0)

	move_and_slide()
	_face_movement(delta)
	_animate(delta)
	_stamina(delta)
	_track_distance()

func _face_movement(delta: float) -> void:
	# In combat, face the locked target; otherwise face travel direction.
	var target_yaw := _face_yaw
	if combat != null and combat.in_combat and combat.target != null:
		var to = combat.target.global_position - global_position
		target_yaw = atan2(to.x, to.z)
	elif move_dir.length() > 0.05:
		target_yaw = atan2(move_dir.x, move_dir.z)
	else:
		return
	_face_yaw = lerp_angle(_face_yaw, target_yaw, minf(1.0, delta * 12.0))
	visual.rotation.y = _face_yaw

func _animate(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if rig != null:
		rig.set_motion(speed / maxf(RUN_SPEED, 0.01) * 5.6)
		rig.set_grounded(is_on_floor())
	# Footsteps: timed by distance, not by clip length, so it never slides.
	if speed > 0.4 and is_on_floor():
		_step_accum += speed * delta
		var stride := 2.6 if is_sprinting else 1.9
		if _step_accum >= stride:
			_step_accum = 0.0
			if footstep != null:
				footstep.stream = load("res://audio/sfx/step_concrete.wav")
				footstep.pitch_scale = randf_range(0.92, 1.08)
				footstep.volume_db = -12.0
				footstep.play()

func _stamina(delta: float) -> void:
	var draining := is_sprinting and move_dir.length() > 0.1
	if draining:
		Game.stamina = maxf(0.0, Game.stamina - 14.0 * delta)
	else:
		Game.stamina = minf(Game.max_stamina, Game.stamina + 9.0 * delta)
	if Game.stamina <= 0.0:
		is_sprinting = false

func _track_distance() -> void:
	var d := global_position.distance_to(_last_pos)
	if d < 4.0:
		Game.stats["distance_walked"] = float(Game.stats.get("distance_walked", 0.0)) + d
	_last_pos = global_position

func is_in_combat() -> bool:
	return combat != null and combat.in_combat

func _on_died() -> void:
	is_dead = true
	if rig != null: rig.play("death")
	await get_tree().create_timer(3.0).timeout
	Game.respawn()
	spawn_at(Game.spawn_point)
	if rig != null: rig.play("stand")
