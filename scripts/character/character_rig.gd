extends Node3D
## CHARACTER RIG — animation owner for every humanoid in LEVERAGE.
##
## Drives a realistic, PBR-textured Mixamo-rigged human (`assets/characters/real/`)
## with a baked 53-clip AnimationLibrary (`assets/characters/baked/<Char>.tres`).
## The baking step lives in `scripts/dev_bake_anims.gd`; see docs/17 for why
## retargeting is done offline (iPhone pays nothing at runtime).
##
## Public API is unchanged from the previous rig so every caller keeps working:
##   build(model_name, scale) -> bool, play(clip), set_locomotion(v, sprinting), ...

## Realistic models on the shared Mixamo skeleton.
const CHAR_DIR := "res://assets/characters/real/"
const BAKED_DIR := "res://assets/characters/baked/"

## Logical model name -> realistic GLB on disk. Content packs still refer to the
## old Quaternius names, so they are mapped instead of rewritten everywhere.
const MODEL_MAP := {
	"casual-male": "Soldier",
	"casual-female": "Michelle",
	"casual2-male": "Soldier",
	"casual2-female": "Michelle",
	"casual3-male": "Soldier",
	"casual3-female": "Michelle",
	"casual-bald": "Soldier",
	"suit-male": "Soldier",
	"suit-female": "Michelle",
	"worker-male": "Soldier",
	"worker-female": "Michelle",
	"xbot": "Xbot",
}

## Semantic clip -> baked clip name. Running is speed-scaled walking (the Run clip
## does not retarget cleanly; see docs/17_ASSET_PIPELINE.md).
const CLIP := {
	"idle": "idle", "walk": "walk", "run": "walk", "jog": "walk", "sprint": "walk",
	"jump": "jump", "punch": "punch", "punch_combo": "punch_combo",
	"punch_cross": "punch_cross", "punch_hook": "punch_hook",
	"kick": "kick", "kick_round": "kick_round", "kick_mma": "kick_mma",
	"kick_knee": "kick_knee", "block": "block", "block_idle": "block_idle",
	"block_hit": "block_hit", "hit": "hit", "hit_body": "hit_body",
	"hit_head": "hit_head", "hit_big": "hit_big", "roll": "roll",
	"dodge_roll": "dodge_roll", "death": "die", "die": "die", "die_back": "die_back",
	"aim": "aim", "aim_gun": "aim_gun", "reload": "reload", "fire": "fire_rifle",
	"talk": "talk", "phone_talk": "phone_talk", "wave": "wave",
	"angry": "angry", "beckon": "beckon", "cover": "cover",
	"drink": "drink", "crouch_idle": "crouch_idle", "sit": "drink",
	"stand": "idle", "pickup": "punch", "victory": "wave", "defeat": "hit_big",
	"slash": "punch", "shoot": "fire_rifle", "walk_carry": "walk", "run_carry": "walk",
}

## Locomotion clips that must loop; everything else is a one-shot.
const LOOPING := ["idle", "walk", "block_idle", "aim", "aim_gun", "cover", "crouch_idle"]

var model_path := ""
var anim_player: AnimationPlayer
var model: Node3D
var skeleton: Skeleton3D
## Extra playback rate applied on top of the clip's own speed. Running a walk clip
## at ~1.55x is what turns it into a believable run without a dedicated run clip.
var speed_scale := 1.0
var is_fighter := false
var model_name := ""

var _current_clip := ""
var _one_shot_until := 0.0
var _base_rate := 1.0

static var _lib_cache: Dictionary = {}

func _ready() -> void:
	set_process(true)

## Load the character model + its baked animation library. Safe to call once.
func build(p_model_name: String, scale_factor: float = 1.0) -> bool:
	if model != null:
		return true
	model_name = p_model_name
	var glb_name: String = MODEL_MAP.get(p_model_name, "Soldier")
	model_path = CHAR_DIR + glb_name + ".glb"
	if not ResourceLoader.exists(model_path):
		return false
	var ps: PackedScene = load(model_path)
	if ps == null:
		return false
	model = ps.instantiate()
	# Realistic models are authored at true human scale already, so the requested
	# factor only nudges body size variation.
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = 0.0
	add_child(model)

	var aps := model.find_children("*", "AnimationPlayer", true, false)
	var sks := model.find_children("*", "Skeleton3D", true, false)
	anim_player = aps[0] if aps.size() > 0 else null
	skeleton = sks[0] if sks.size() > 0 else null
	if anim_player == null:
		return model != null

	_upgrade_materials(model)

	var lib: AnimationLibrary = _library_for(glb_name)
	if lib != null:
		anim_player.add_animation_library("mocap", lib)
		# The baked tracks are relative to the model root ("Character/Skeleton3D:..."),
		# but the AnimationPlayer ships with root_node = "..". Godot resolves that
		# NodePath lazily and caches it, and in a runtime-built hierarchy it caches
		# a STALE path -- ap.get_node_or_null("Character/Skeleton3D") returned null
		# even though the node plainly existed, so every track was unbound and the
		# mesh sat in its bind pose. Assigning root_node explicitly after the player
		# is in the tree forces a correct resolution.
		anim_player.root_node = NodePath("..")
		_verify_binding()
		play("idle")
	return true

## Cached per-character baked library.
func _library_for(glb_name: String) -> AnimationLibrary:
	if _lib_cache.has(glb_name):
		return _lib_cache[glb_name]
	# Binary .res loads faster and is 59% smaller than the text .tres was:
	# baked animation data is binary, so serialising it as text cost 33 MB.
	# .tres remains as a fallback for any character not yet converted.
	var path := BAKED_DIR + glb_name + ".res"
	if not ResourceLoader.exists(path):
		path = BAKED_DIR + glb_name + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var lib: AnimationLibrary = load(path)
	if lib != null:
		for c in LOOPING:
			var lc: String = CLIP.get(c, c)
			if lib.has_animation(lc):
				lib.get_animation(lc).loop_mode = Animation.LOOP_LINEAR
	_lib_cache[glb_name] = lib
	return lib

## Confirms the animation actually binds. A silent T-pose is the worst kind of
## failure: the game runs, the logs are clean, and every character is wrong.
func _verify_binding() -> void:
	if anim_player == null:
		return
	var anim := anim_player.get_animation(anim_player.current_animation if anim_player.current_animation != "" else "")
	var probe := "mocap/idle"
	if anim_player.has_animation(probe):
		anim = anim_player.get_animation(probe)
	if anim == null or anim.get_track_count() == 0:
		return
	# Track paths resolve relative to root_node, NOT relative to the player.
	# (ap.get_node_or_null("Character/Skeleton3D") returns null even when the
	# animation binds perfectly -- probe through root_node instead.)
	var rn := anim_player.get_node_or_null(anim_player.root_node)
	if rn == null:
		print("[RIG] WARNING: root_node ", anim_player.root_node, " does not resolve")
		return
	var unbound := 0
	for i in anim.get_track_count():
		var np := String(anim.track_get_path(i)).get_slice(":", 0)
		if rn.get_node_or_null(np) == null:
			unbound += 1
	if unbound > 0:
		print("[RIG] WARNING: ", unbound, "/", anim.get_track_count(),
			" animation tracks unbound on ", model_name, " - character will T-pose")

func _process(delta: float) -> void:
	if anim_player == null:
		return
	if _one_shot_until > 0.0:
		if Time.get_ticks_msec() / 1000.0 >= _one_shot_until:
			_one_shot_until = 0.0
			play("idle")

## Play a semantic clip. `rate` overrides playback speed for this clip only.
func play(clip: String, rate: float = 1.0, blend: float = 0.18) -> void:
	if anim_player == null:
		return
	var target: String = CLIP.get(clip, clip)
	if not anim_player.has_animation("mocap/" + target):
		target = "idle"
	var full := "mocap/" + target
	if _current_clip == full and anim_player.is_playing():
		return
	_current_clip = full
	anim_player.play(full, blend)
	if rate != 1.0:
		anim_player.speed_scale = rate
	else:
		anim_player.speed_scale = 1.0

## One-shot clip that returns to idle when it finishes.
func play_once(clip: String, rate: float = 1.0) -> void:
	play(clip, rate)
	if anim_player == null:
		return
	var full := "mocap/" + str(CLIP.get(clip, clip))
	if anim_player.has_animation(full):
		var a: Animation = anim_player.get_animation(full)
		_one_shot_until = Time.get_ticks_msec() / 1000.0 + maxf(0.15, a.length / maxf(0.1, rate))

## Locomotion driver: picks walk/idle and scales the rate with speed so the feet
## keep pace with the capsule instead of sliding.
func set_locomotion(speed: float, sprinting := false) -> void:
	if speed < 0.15:
		play("idle")
		return
	# Walk clip cadence is ~1.4 m/s; scale from there. Sprinting pushes it harder
	# and the player controller adds a forward lean on top.
	var ref := 1.4
	play("walk", clampf(absf(speed) / ref, 0.55, 2.35))

## Tuning pass over realistic character materials. These GLBs ship real PBR
## textures (diffuse/normal/glossiness), so unlike the old cartoon rig we must NOT
## replace them — only fix up properties that read badly on the Mobile renderer.
func _upgrade_materials(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var src := mesh.surface_get_material(si) as BaseMaterial3D
			if src == null:
				continue
			var mat := src.duplicate() as BaseMaterial3D
			# Skin and cloth should never look wet; armour keeps a little sheen.
			mat.roughness = clampf(mat.roughness * 1.15 + 0.12, 0.0, 1.0)
			# Gonzo-scale specular on stylised models reads as plastic under ACES.
			mat.metallic_specular = clampf(mat.metallic_specular, 0.25, 0.6)
			mat.backlight_enabled = false
			mi.set_surface_override_material(si, mat)

## React to being hit: play the appropriate stagger and return to idle.
func hit_react(strength: float = 1.0) -> void:
	if anim_player == null:
		return
	var clip := "hit_big" if strength > 1.6 else ("hit_head" if strength > 1.1 else "hit")
	play_once(clip)

## Death animation; leaves the rig on its final frame.
func die() -> void:
	play("die")
	if anim_player != null:
		anim_player.pause()

## Rotate the body to face a movement direction, smoothly.
func face_direction(dir: Vector3, delta: float, turn_rate := 12.0) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_rate * delta, 0.0, 1.0))

## Seconds the current one-shot still has to run (0 = free to interrupt).
func busy_time() -> float:
	return maxf(0.0, _one_shot_until - Time.get_ticks_msec() / 1000.0)

## --- compatibility shims -------------------------------------------------
## Callers from the previous (blend-space) rig call set_motion/set_grounded.
## They map onto the clip-based driver so no caller had to change.

var _motion := 0.0

## `value` is a raw blend-space speed (roughly 0..5.6). Convert back to m/s so the
## locomotion driver can pick walk/idle and the right cadence.
func set_motion(value: float) -> void:
	_motion = value
	var mps: float = value / 5.6 * 7.0
	if mps > 0.15:
		set_locomotion(mps, mps > 5.2)
	else:
		play("idle")

func set_grounded(_grounded: bool) -> void:
	pass
