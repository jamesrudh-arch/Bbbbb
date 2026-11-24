extends Node3D
## CHARACTER RIG — animation owner for every humanoid in LEVERAGE.
## Loads one of the Quaternius Universal Animated Character GLBs (17 shared
## clips) and drives an AnimationTree blend space so movement is continuous,
## never a hard snap between clips. Fighters and pedestrians share this rig.

const ANIM_LIB := "res://assets/characters/anim/animations.glb"
const CHAR_DIR := "res://assets/characters/players/"

# Clip names as authored in the UAC pack.
const CLIP := {
	"idle": "Idle", "walk": "Walk", "run": "Run", "jump": "Jump",
	"punch": "Punch", "hit": "RecieveHit", "roll": "Roll", "death": "Death",
	"sit": "SitDown", "stand": "StandUp", "pickup": "PickUp",
	"slash": "SwordSlash", "shoot": "Shoot_OneHanded", "victory": "Victory",
	"walk_carry": "Walk_Carry", "run_carry": "Run_Carry", "defeat": "Defeat",
}

static var _lib_cache: AnimationLibrary = null

var model_path := ""
var anim_tree: AnimationTree
var anim_player: AnimationPlayer
var model: Node3D
var speed_scale := 1.0
var is_fighter := false

var _ready_done := false
var _current_clip := ""
var _one_shot_until := 0.0

func _ready() -> void:
	_ready_done = true
	set_process(true)

## Load the character model + shared animation library. Safe to call once.
func build(model_name: String, scale_factor: float = 1.0) -> bool:
	if model != null: return true
	model_path = CHAR_DIR + model_name + ".glb"
	if not ResourceLoader.exists(model_path):
		return false
	var ps := load(model_path)
	if ps == null: return false
	model = ps.instantiate()
	model.scale = Vector3.ONE * scale_factor
	# Feet-on-floor correction: UAC rigs are centre-origin, the game world is
	# floor-origin. 1.0 m of lift puts the soles exactly on y = 0.
	model.position.y = 1.0 * scale_factor
	# UAC/misty characters are authored facing +Z; Godot's forward is -Z.
	# Without this every character moonwalks — they walk forward while facing back.
	model.rotation.y = PI
	add_child(model)
	_tint_materials(model)

	anim_player = AnimationPlayer.new()
	anim_player.name = "AP"
	model.add_child(anim_player)
	# Ensure the whole subtree is inside the SceneTree before any node paths are
	# resolved (AnimationTree needs anim_player's path to exist).
	if not is_inside_tree() and get_parent() != null and get_parent().is_inside_tree():
		pass

	# Build (once per process) the shared library from the UAC animation GLB.
	var lib := _shared_library()
	if lib != null:
		anim_player.add_animation_library("", lib)
		anim_tree = AnimationTree.new()
		anim_tree.name = "AT"
		add_child(anim_tree)
		# Resolve the path only once the tree node exists.
		anim_tree.anim_player = anim_tree.get_path_to(anim_player)
		_setup_blend()
		play("idle")
	else:
		# No library: at least fall back to any clips bundled in the model.
		if anim_player.get_animation_list().size() > 0:
			anim_player.play()
	return true

const LIB_CACHE := "user://anim_lib_cache.res"

## The misty-3d characters ship with near-black base colours (Skin linear 0.013),
## which renders as a black blob. Re-art-direct them into Cinder City's palette
## so skin, shirt, jeans, hair and face read clearly under Mobile lighting.
const PALETTE := {
	"Skin":  Color(0.62, 0.42, 0.29),
	"Face":  Color(0.86, 0.72, 0.58),
	"Shirt": Color(0.16, 0.24, 0.38),
	"Pants": Color(0.13, 0.14, 0.18),
	"Belt":  Color(0.10, 0.08, 0.07),
	"Hair":  Color(0.09, 0.06, 0.05),
}
const SKIN_VARIANTS := [
	Color(0.62, 0.42, 0.29), Color(0.46, 0.30, 0.20), Color(0.30, 0.19, 0.13),
	Color(0.75, 0.58, 0.45), Color(0.53, 0.35, 0.24),
]
const SHIRT_VARIANTS := [
	Color(0.16, 0.24, 0.38), Color(0.42, 0.13, 0.15), Color(0.20, 0.32, 0.24),
	Color(0.55, 0.42, 0.12), Color(0.22, 0.22, 0.26), Color(0.34, 0.20, 0.42),
]

func _tint_materials(root: Node) -> void:
	var skin: Color = SKIN_VARIANTS[randi() % SKIN_VARIANTS.size()]
	var shirt: Color = SHIRT_VARIANTS[randi() % SHIRT_VARIANTS.size()]
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var count := mi.mesh.get_surface_count() if mi.mesh != null else 0
		for si in count:
			var src := mi.mesh.surface_get_material(si) as BaseMaterial3D
			if src == null: continue
			var mat := StandardMaterial3D.new()
			mat.roughness = 0.72
			mat.metallic = 0.0
			match src.resource_name:
				"Skin": mat.albedo_color = skin
				"Face": mat.albedo_color = skin.lerp(Color(1,1,1), 0.35)
				"Shirt": mat.albedo_color = shirt
				"Pants": mat.albedo_color = Color(0.23, 0.26, 0.34).lerp(shirt, 0.14)
				"Belt": mat.albedo_color = Color(0.10, 0.08, 0.07)
				"Hair": mat.albedo_color = Color(0.09, 0.06, 0.05).lerp(Color(0.25,0.16,0.10), randf())
				_: mat.albedo_color = src.albedo_color if src.albedo_color != Color.BLACK else Color(0.5,0.5,0.5)
			mi.set_surface_override_material(si, mat)

static func _shared_library() -> AnimationLibrary:
	if _lib_cache != null: return _lib_cache
	# Fast path: a previously built library resource.
	if ResourceLoader.exists(LIB_CACHE):
		var cached = load(LIB_CACHE)
		if cached is AnimationLibrary and cached.get_animation_list().size() > 0:
			_lib_cache = cached
			return _lib_cache
	if not ResourceLoader.exists(ANIM_LIB): return null
	var ps := load(ANIM_LIB)
	if ps == null: return null
	var inst = ps.instantiate()
	var ap: AnimationPlayer = _find_ap(inst)
	if ap == null:
		inst.queue_free()
		return null
	var lib := AnimationLibrary.new()
	for clip in ap.get_animation_list():
		var a: Animation = ap.get_animation(clip)
		if a == null: continue
		lib.add_animation(clip, a)
	inst.queue_free()
	_lib_cache = lib
	# Cache for subsequent actors / runs.
	if lib.get_animation_list().size() > 0:
		ResourceSaver.save(lib, LIB_CACHE)
	return lib

static func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null: return r
	return null

func _setup_blend() -> void:
	var sm := AnimationNodeStateMachine.new()

	# Locomotion blend space: idle -> walk -> run driven by `speed` param.
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = 6.0
	for pair in [[0.0, "Idle"], [2.2, "Walk"], [5.6, "Run"]]:
		var ap := AnimationNodeAnimation.new()
		ap.animation = pair[1]
		loco.add_blend_point(ap, pair[0])

	# Airborne
	var jump := AnimationNodeAnimation.new()
	jump.animation = "Jump"
	var air := AnimationNodeStateMachinePlayback
	var sm_air := AnimationNodeStateMachine.new()
	sm_air.add_node("Jump", jump)

	sm.add_node("loco", loco)
	sm.add_node("jump", sm_air)
	sm.add_transition("loco", "jump", _cond("grounded", false))
	sm.add_transition("jump", "loco", _cond("grounded", true))
	anim_tree.tree_root = sm
	anim_tree.set("parameters/speed/blend_position", 0.0)
	anim_tree.set("parameters/grounded", true)
	anim_tree.active = true

func _cond(param: String, value: bool) -> AnimationNodeStateMachineTransition:
	var t := AnimationNodeStateMachineTransition.new()
	t.advance_condition = param
	t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	return t

## Set the locomotion blend (0 idle .. 6 sprint).
func set_motion(speed: float) -> void:
	if anim_tree == null: return
	anim_tree.set("parameters/speed/blend_position", clampf(speed, 0.0, 6.0))
	if _current_clip == "" or _current_clip == "loco":
		return

func set_grounded(g: bool) -> void:
	if anim_tree != null:
		anim_tree.set("parameters/grounded", g)

## Play a named clip once (attacks, hits, interactions), then return to locomotion.
func play(clip_key: String, speed: float = 1.0) -> void:
	if anim_player == null: return
	var clip: String = CLIP.get(clip_key, clip_key)
	if not anim_player.has_animation(clip): return
	if anim_tree != null:
		# Temporarily drive the AnimationPlayer directly for one-shots so they
		# layer cleanly over the blend space.
		anim_tree.active = false
	anim_player.play(clip, 0.12, speed)
	var len := anim_player.get_animation(clip).length / maxf(speed, 0.01)
	_one_shot_until = Time.get_ticks_msec() / 1000.0 + len
	_current_clip = clip_key
	set_process(true)

func _process(_d: float) -> void:
	if _one_shot_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _one_shot_until:
		_one_shot_until = 0.0
		_current_clip = ""
		if anim_tree != null:
			anim_tree.active = true
			set_grounded(true)
		elif anim_player != null:
			anim_player.play("Idle")

## Stagger: brief hit reaction that does not interrupt a death animation.
func hit_react() -> void:
	if _current_clip == "death": return
	play("hit", 1.25)
