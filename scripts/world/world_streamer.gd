extends Node
## WORLD STREAMER — distance-based simulation for mobile.
## Geometry stays resident (it is instanced once and cheap), but distant
## districts stop simulating actors and switch to a frozen visual state.
## Quality scaling steps in when frame time degrades.

var world: Node3D
var districts: Dictionary = {}
var _far := ["ash_row", "iron_yard", "vesper_heights", "neon_mile"]
var _timer := 0.0
var _quality := 2
var _slow_frames := 0

const FAR_RANGE := 145.0
## Draw range for full district geometry. Kept equal to the simulation range:
## with authored streets a district is visually dense, so anything beyond one
## block away is fog anyway and not worth the draw calls.

func setup(w: Node3D, d: Dictionary) -> void:
	world = w
	districts = d

func _process(delta: float) -> void:
	_timer += delta
	if _timer < 1.0: return
	_timer = 0.0
	if world == null or world.player == null: return
	var pp: Vector3 = world.player.global_position
	for id in districts:
		var c: Vector3 = world.builder.district_center(id)
		var d := Vector2(pp.x - c.x, pp.z - c.z).length()
		var near := d < FAR_RANGE
		var node: Node3D = districts[id]
		node.visible = d < FAR_RANGE
		# Freeze distant simulation flags consumed by NPC / traffic actors.
		node.set_meta("sim_active", near)
	_scale_quality()

func _scale_quality() -> void:
	var fps := Engine.get_frames_per_second()
	if fps > 0.0 and fps < 26.0:
		_slow_frames += 1
		if _slow_frames >= 3 and _quality > 0:
			_quality -= 1
			_slow_frames = 0
			_apply_quality()
	elif fps > 51.0 and _quality < 2:
		_slow_frames -= 1
		if _slow_frames <= -6:
			_quality += 1
			_slow_frames = 0
			_apply_quality()

func _apply_quality() -> void:
	var vp := get_viewport()
	if _quality == 2:
		vp.scaling_3d_scale = 1.0
	elif _quality == 1:
		vp.scaling_3d_scale = 0.82
	else:
		vp.scaling_3d_scale = 0.68
	# Shadow distance and glow follow the same ladder.
	var sun = world.sun if world else null
	if sun != null:
		sun.directional_shadow_max_distance = [55.0, 80.0, 100.0][_quality]
	if world != null and world.environment != null:
		world.environment.environment.glow_enabled = _quality >= 1
