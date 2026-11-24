extends Node3D
## STREET CROWD — the animated half of the street population.
##
## Why this file exists: a street reads as dead if its only people are standing
## in the bind pose. The static crowd (street_kit.populate_people) is free and
## correct at distance, but a player standing at a stall next to a frozen figure
## notices immediately. So the nearest street in each visible district also gets
## real animation, and everyone else stays static.
##
## Cost control, which is the whole design here:
##   * the figures share ONE AnimationLibrary resource; only the players are
##     per-figure, because a clip's tracks are addressed through the figure's own
##     armature and cannot be re-pointed at a sibling. This is exactly what
##     character_rig.gd does for actors.
##   * the count is capped hard (MAX_ANIMATED). Each figure is a skeleton, and
##     skinning is the frame cost, not the player object.
##   * figures are spread over the street rather than clustered, so the player
##     meets them one at a time instead of paying for all of them at once.
##
## The clips come from the shared UAC library the actors already ship, so the
## crowd walks like the cast and costs no extra animation data.

const ANIM_LIB := "res://assets/characters/anim/animations.glb"
const CHAR_DIR := "res://assets/characters/players/"

## How many figures may be animated at once.
const MAX_ANIMATED := 14

## Clips the crowd cycles through. Walk is the common case; the rest keep a
## pavement from looking like a treadmill.
const CROWD_CLIPS := ["Walk", "Walk", "Walk", "Idle"]

const MODELS := ["casual-male", "casual-female", "casual2-male", "casual2-female",
	"casual3-male", "casual3-female", "worker-male", "worker-female", "casual-bald"]

const SKIN_TONES := [Color(0.62, 0.42, 0.29), Color(0.46, 0.30, 0.20),
	Color(0.30, 0.19, 0.13), Color(0.75, 0.58, 0.45), Color(0.53, 0.35, 0.24)]
const SHIRT_COLS := [Color(0.86, 0.30, 0.22), Color(0.22, 0.44, 0.66),
	Color(0.92, 0.74, 0.26), Color(0.30, 0.56, 0.38), Color(0.88, 0.88, 0.86),
	Color(0.62, 0.32, 0.62), Color(0.34, 0.34, 0.36), Color(0.94, 0.50, 0.20)]

static var _lib_cache: AnimationLibrary = null

var _spawned: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()

# --------------------------------------------------------------- public API

## Build `count` animated pedestrians along a straight run of `length` metres
## starting at `from`, running along `dir`. Figures go on both pavements.
func build(origin: Vector3, dir: Vector3, length: float, count: int, seed_value: int) -> void:
	clear()
	_rng.seed = seed_value
	position = origin
	var fwd := -dir.normalized()
	var lib := _shared_library()
	if lib == null:
		push_warning("StreetCrowd: no animation library; crowd stays static")
		return

	var n := clampi(count, 0, MAX_ANIMATED)
	var side := Vector3(fwd.z, 0.0, -fwd.x)   # right-hand normal on the ground plane
	for i in n:
		var t := (float(i) + _rng.randf_range(0.15, 0.85)) / float(maxi(n, 1)) * length
		var lateral: float = _rng.randf_range(4.6, 6.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var fig := _spawn_figure(fwd * t + side * lateral, fwd, lib)
		if fig != null:
			_spawned.append(fig)

## Remove the crowd. Safe to call at any time, including before build().
func clear() -> void:
	_spawned.clear()
	for c in get_children():
		c.queue_free()

func count() -> int:
	var live := 0
	for f in _spawned:
		if is_instance_valid(f):
			live += 1
	return live

# --------------------------------------------------------------- internals

func _spawn_figure(pos: Vector3, fwd: Vector3, lib: AnimationLibrary) -> Node3D:
	var nm: String = MODELS[_rng.randi_range(0, MODELS.size() - 1)]
	var path := CHAR_DIR + nm + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var fig: Node3D = ps.instantiate()
	# Two currents of foot traffic, so the pavement is not a parade.
	var face: Vector3 = fwd if _rng.randf() < 0.5 else -fwd
	fig.position = pos
	fig.rotation.y = atan2(face.x, face.z)
	var s := 0.92 * _rng.randf_range(0.94, 1.05)
	fig.scale = Vector3.ONE * s
	add_child(fig)
	_tint(fig)
	_ground(fig, s)
	_animate(fig, lib)
	return fig

## Attach a player to this figure and start a clip at a random phase. The player
## is parented INTO the figure so the clip's "CharacterArmature/Skeleton3D:..."
## paths resolve against that figure's own armature.
func _animate(fig: Node3D, lib: AnimationLibrary) -> void:
	var ap := AnimationPlayer.new()
	ap.name = "CrowdAnim"
	fig.add_child(ap)
	ap.add_animation_library("", lib)
	var clip: String = CROWD_CLIPS[_rng.randi_range(0, CROWD_CLIPS.size() - 1)]
	if not ap.has_animation(clip):
		clip = "Walk" if ap.has_animation("Walk") else ap.get_animation_list()[0]
	var anim := ap.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	ap.play(clip)
	# Desync: without this the street walks in unison, which reads as a chorus
	# line rather than as a crowd.
	var at: float = _rng.randf_range(0.0, maxf(anim.length - 0.05, 0.05)) if anim != null else 0.0
	ap.seek(at, true)

## Same art direction rules as street_kit._tint_person, so animated and static
## people look like they belong to the same city.
func _tint(root: Node) -> void:
	var skin: Color = SKIN_TONES[_rng.randi_range(0, SKIN_TONES.size() - 1)]
	var shirt: Color = SHIRT_COLS[_rng.randi_range(0, SHIRT_COLS.size() - 1)]
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(si) as BaseMaterial3D
			if src == null:
				continue
			var mat := StandardMaterial3D.new()
			mat.roughness = 0.74
			mat.metallic = 0.0
			match src.resource_name:
				"Skin": mat.albedo_color = skin
				"Face": mat.albedo_color = skin.lerp(Color(1, 1, 1), 0.34)
				"Shirt": mat.albedo_color = shirt
				"Pants": mat.albedo_color = Color(0.14, 0.15, 0.19).lerp(shirt, 0.16)
				"Belt": mat.albedo_color = Color(0.10, 0.08, 0.07)
				"Hair": mat.albedo_color = Color(0.08, 0.06, 0.05)
				_: mat.albedo_color = src.albedo_color
			mi.set_surface_override_material(si, mat)

## The bind pose floats: a skinned mesh's AABB is the bind pose, not the posed
## figure, so measure through the skeleton and drop the lowest bone to y = 0.
func _ground(fig: Node3D, s: float) -> void:
	var sk: Skeleton3D = null
	for nn in fig.find_children("*", "Skeleton3D", true, false):
		sk = nn as Skeleton3D
		break
	if sk != null and sk.get_bone_count() > 0:
		var lo := 1e9
		for b in sk.get_bone_count():
			lo = minf(lo, sk.get_bone_global_rest(b).origin.y)
		fig.position.y = -lo * s

## One library per process, shared by every figure's player. Clips are read-only
## resources, so sharing them costs nothing.
static func _shared_library() -> AnimationLibrary:
	if _lib_cache != null:
		return _lib_cache
	if not ResourceLoader.exists(ANIM_LIB):
		return null
	var ps: PackedScene = load(ANIM_LIB)
	if ps == null:
		return null
	var inst = ps.instantiate()
	var ap: AnimationPlayer = null
	for n in inst.find_children("*", "AnimationPlayer", true, false):
		ap = n as AnimationPlayer
		break
	if ap == null:
		inst.free()
		return null
	var lib := AnimationLibrary.new()
	for clip in ap.get_animation_list():
		var a: Animation = ap.get_animation(clip)
		if a != null:
			lib.add_animation(clip, a)
	inst.free()
	_lib_cache = lib
	return lib
