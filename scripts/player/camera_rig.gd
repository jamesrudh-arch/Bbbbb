extends Node3D
## CAMERA RIG — professional third-person orbit camera.
## SpringArm collision keeps the view out of walls; yaw/pitch are smoothed;
## touch drag rotates, movement input auto-recentres when you run forward.

@export var yaw_speed := 4.4
@export var pitch_speed := 2.6
@export var pitch_min := -0.62
@export var pitch_max := 0.32
@export var follow_height := 1.75
@export var follow_smoothing := 9.0
@export var auto_recentre := 0.35

var target_node: Node3D = null
var yaw := PI * 0.5
var pitch := -0.10
var spring: SpringArm3D
var camera: Camera3D
var _follow_target_position := Vector3.ZERO
var _shake := 0.0
var _initialised := false
var _touch_id := -1
var _last_touch := Vector2.ZERO
var _vehicle = null

func _ready() -> void:
	spring = $SpringArm3D
	camera = $SpringArm3D/Camera3D
	spring.spring_length = 6.2
	spring.collision_mask = 1 | 8
	spring.margin = 0.35
	var rid := _player_rid()
	if rid.is_valid():
		spring.add_excluded_object(rid)

func _player_rid() -> RID:
	var p = get_parent()
	if p is CollisionObject3D:
		return p.get_rid()
	return RID()

func clear_target() -> void:
	target_node = null
	_initialised = false

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if _touch_id < 0 or event.index == _touch_id:
			_touch_id = event.index
			var d: Vector2 = event.relative
			yaw -= d.x * 0.0052
			pitch = clampf(pitch - d.y * 0.0038, pitch_min, pitch_max)
	elif event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.32:
			_touch_id = event.index
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0032
		pitch = clampf(pitch - event.relative.y * 0.0024, pitch_min, pitch_max)

func _process(delta: float) -> void:
	# Gamepad right-stick look
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(rx) > 0.15: yaw -= rx * yaw_speed * delta
	if absf(ry) > 0.15: pitch = clampf(pitch - ry * pitch_speed * delta, pitch_min, pitch_max)

	if _vehicle != null:
		_follow_vehicle(delta)
		return
	if target_node == null: return

	var focus: Vector3 = target_node.global_position + Vector3(0, follow_height, 0)
	if not _initialised:
		_initialised = true
		_follow_target_position = focus
		global_position = focus
	_follow_target_position = _follow_target_position.lerp(focus, minf(1.0, delta * follow_smoothing))
	global_position = _follow_target_position
	rotation = Vector3(pitch, yaw, 0)
	# Auto-recentre yaw toward travel direction when running forward on touch.
	if target_node is CharacterBody3D:
		var md: Vector3 = target_node.move_dir
		if md.length() > 0.4 and _touch_id < 0:
			var want := atan2(md.x, md.z)
			yaw = lerp_angle(yaw, want, delta * auto_recentre)
	if _shake > 0.0:
		camera.h_offset = randf_range(-_shake, _shake) * 0.35
		camera.v_offset = randf_range(-_shake, _shake) * 0.35
		_shake = maxf(0.0, _shake - delta * 2.4)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

func attach_vehicle(v) -> void:
	_vehicle = v
	spring.spring_length = 8.2

func detach_vehicle() -> void:
	_vehicle = null
	spring.spring_length = 5.4
	_initialised = false

func _follow_vehicle(delta: float) -> void:
	if _vehicle == null or not is_instance_valid(_vehicle): return
	var focus: Vector3 = _vehicle.global_position + Vector3(0, 2.3, 0)
	_follow_target_position = _follow_target_position.lerp(focus, minf(1.0, delta * 7.0))
	global_position = _follow_target_position
	var want_yaw: float = _vehicle.rotation.y + PI
	yaw = lerp_angle(yaw, want_yaw, delta * 3.2)
	rotation = Vector3(-0.17, yaw, 0)

func current_yaw() -> float:
	return yaw
