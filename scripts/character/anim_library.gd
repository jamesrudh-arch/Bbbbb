class_name AnimLibrary
extends RefCounted
## Builds a single AnimationLibrary from the Mixamo clip GLBs in
## res://assets/characters/animlib. Every clip shares the `RootNode/mixamorig_*`
## skeleton path, so the same library drives any Mixamo-rigged character
## (Soldier, Michelle, Xbot and any future model on that skeleton).
##
## Clip GLBs each hold exactly one animation named "mixamo_com"; we rename it to
## the file's base name so callers can ask for e.g. "Run" or "Roundhouse_Kick".

const ANIM_DIR := "res://assets/characters/animlib"

## file base name -> library clip name
const CLIPS := {
	"Idle": "idle",
	"Standing_Idle": "idle_alt",
	"Injured_Idle": "idle_injured",
	"Walk": "walk",
	"Jog_Forward": "jog",
	"Run": "run",
	"Standard_Run": "run_std",
	"Running": "running",
	"Slow_Run": "slow_run",
	"Jogging": "jogging",
	"Run_Forward": "run_forward",
	"Sprint": "sprint",
	"Crouch_Idle": "crouch_idle",
	"Crouch_Running": "crouch_run",
	"Jump": "jump",
	"Forward_Jump": "jump_forward",
	"Running_Dive_Roll": "dodge_roll",
	"Dive_Roll": "roll",
	"Standing_Dodge_Forward": "dodge_forward",
	"Standing_Dodge_Left": "dodge_left",
	"Turn_Right": "turn",
	"Punching": "punch",
	"Punch_Combo": "punch_combo",
	"Cross_Punch": "punch_cross",
	"Hook_Punch": "punch_hook",
	"Quad_Punch": "punch_quad",
	"Combo_Punch": "punch_combo2",
	"Kicking": "kick",
	"Roundhouse_Kick": "kick_round",
	"Mma_Kick": "kick_mma",
	"Flying_Kick": "kick_fly",
	"Knee_Kick_Lead": "kick_knee",
	"Blocking": "block",
	"Standing_Block_Idle": "block_idle",
	"Standing_Block_Start": "block_start",
	"Standing_Block_React_Large": "block_hit",
	"Hit_Reaction": "hit",
	"Hit_To_Body": "hit_body",
	"Hit_To_Head": "hit_head",
	"Medium_Hit_To_Head": "hit_head_mid",
	"Getting_Hit_Backwards": "hit_back",
	"Big_Hit_To_Head": "hit_big",
	"Death": "die",
	"Standing_Death_Backward_01": "die_back",
	"Death_From_The_Front": "die_front",
	"Aim_Pistol": "aim",
	"Aiming_Gun": "aim_gun",
	"Reload": "reload",
	"Firing_Rifle": "fire_rifle",
	"Talking": "talk",
	"Talking_On_Phone": "phone_talk",
	"Waving": "wave",
	"Angry_Gesture": "angry",
	"Beckoning": "beckon",
	"Cover_Idle": "cover",
	"Idle_Crouching_Aiming": "crouch_aim",
	"Drinking": "drink",
	"Injured_Run": "run_injured",
}

static var _cache: AnimationLibrary = null

## Returns a shared AnimationLibrary containing every clip that exists on disk.
static func build() -> AnimationLibrary:
	if _cache != null:
		return _cache
	var lib := AnimationLibrary.new()
	for file_base in CLIPS:
		var path := "%s/%s.glb" % [ANIM_DIR, file_base]
		if not ResourceLoader.exists(path):
			continue
		var packed: PackedScene = load(path)
		if packed == null:
			continue
		var inst := packed.instantiate()
		var aps := inst.find_children("*", "AnimationPlayer", true, false)
		if aps.is_empty():
			inst.free()
			continue
		var src: AnimationPlayer = aps[0]
		var names := src.get_animation_list()
		if names.is_empty():
			inst.free()
			continue
		# Clip GLBs hold one animation called "mixamo_com"; take the first regardless.
		var anim: Animation = src.get_animation(names[0]).duplicate(true)
		anim.loop_mode = Animation.LOOP_NONE
		lib.add_animation(CLIPS[file_base], anim)
		inst.free()
	_cache = lib
	return _cache

## Clips that should loop seamlessly (locomotion + held poses).
static func looping_clips() -> PackedStringArray:
	return PackedStringArray([
		"idle", "idle_alt", "idle_injured", "walk", "jog", "run", "sprint",
		"crouch_idle", "crouch_run", "block_idle", "cover", "aim", "aim_gun",
		"crouch_aim", "phone_talk", "talk",
	])

## Apply loop flags to a built library.
static func apply_loops(lib: AnimationLibrary) -> void:
	for clip in looping_clips():
		if not lib.has_animation(clip):
			continue
		var a: Animation = lib.get_animation(clip)
		if a != null:
			a.loop_mode = Animation.LOOP_LINEAR

## ---------------------------------------------------------------------------
## Retargeting
## ---------------------------------------------------------------------------
## The Mixamo clip GLBs store node tracks under "RootNode/mixamorig_*", but the
## character GLBs put their bones inside a Skeleton3D node (typically
## "Character/Skeleton3D"). Godot addresses a bone with the `node:bone` syntax,
## so every track has to be rewritten to "<skeleton_path>:<bone_name>" before the
## clip will drive the skeleton. Bone NAMES are identical across Mixamo rigs, so
## the mapping is a straight name match.

## Returns a retargeted copy of `lib` whose tracks address `skeleton_path`.
## Reference-rig rest rotations, captured once from a clip GLB. Mixamo clips store
## ABSOLUTE bone orientations, and different character GLBs bake their own rest
## orientation (Soldier's hips rest is a 180 deg rotation, the clip rig's is
## identity). Copying clip values straight onto a character therefore tips the
## body over. Applying each clip value as a DELTA from the reference rest, on top
## of the character's own rest, is the correct retarget.
static var _ref_rest: Dictionary = {}
static var _ref_captured := false

static func _capture_ref_rest() -> void:
	if _ref_captured:
		return
	var probe := "%s/Run.glb" % ANIM_DIR
	if not ResourceLoader.exists(probe):
		return
	var inst: Node = (load(probe) as PackedScene).instantiate()
	var root: Node = inst.get_node_or_null("RootNode")
	if root != null:
		_capture_recursive(root)
	inst.free()
	_ref_captured = true

static func _capture_recursive(n: Node) -> void:
	if n is Node3D and String(n.name).begins_with("mixamorig_"):
		_ref_rest[String(n.name)] = (n as Node3D).transform.basis.get_rotation_quaternion()
	for c in n.get_children():
		_capture_recursive(c)

## Retargets `lib` onto `skeleton` (a Skeleton3D). Rotation tracks become deltas
## from the reference rig rest applied onto the character rest; the hips
## translation is rebased onto the character's hips rest so the body stays seated
## on its capsule.
static func retarget_to(lib: AnimationLibrary, skeleton: Skeleton3D, skeleton_path := "Character/Skeleton3D", keep_hips_rest := true) -> AnimationLibrary:
	_capture_ref_rest()
	var out := AnimationLibrary.new()
	var hips_idx: int = skeleton.find_bone("mixamorig_Hips")
	var hips_rest: Vector3 = skeleton.get_bone_rest(hips_idx).origin
	var rest_cache: Dictionary = {}
	for clip in lib.get_animation_list():
		var a: Animation = (lib.get_animation(clip) as Animation).duplicate(true)
		for i in a.get_track_count():
			var bone := _bone_from_path(a.track_get_path(i))
			if bone == "":
				continue
			a.track_set_path(i, NodePath("%s:%s" % [skeleton_path, bone]))
			var tt: int = a.track_get_type(i)
			if tt == Animation.TYPE_ROTATION_3D:
				if bone == "mixamorig_Hips" and keep_hips_rest:
					continue
				var ref_q: Quaternion = _ref_rest.get(bone, Quaternion.IDENTITY)
				var ref_inv: Quaternion = ref_q.inverse()
				if not rest_cache.has(bone):
					var bi := skeleton.find_bone(bone)
					rest_cache[bone] = (skeleton.get_bone_rest(bi).basis.get_rotation_quaternion() if bi >= 0 else Quaternion.IDENTITY)
				var char_q: Quaternion = rest_cache[bone]
				for k in a.track_get_key_count(i):
					var v: Quaternion = a.track_get_key_value(i, k)
					var delta: Quaternion = ref_inv * v
					a.track_set_key_value(i, k, (char_q * delta).normalized())
			elif tt == Animation.TYPE_POSITION_3D and bone == "mixamorig_Hips":
				var base_y := 0.0
				if a.track_get_key_count(i) > 0:
					base_y = (a.track_get_key_value(i, 0) as Vector3).y
				for k in a.track_get_key_count(i):
					var v: Vector3 = a.track_get_key_value(i, k)
					var dy := (v.y - base_y)
					a.track_set_key_value(i, k, Vector3(hips_rest.x, hips_rest.y + dy, hips_rest.z))
		out.add_animation(clip, a)
	return out

static func _bone_from_path(p: NodePath) -> String:
	var s := str(p)
	var colon := s.rfind(":")
	if colon != -1:
		var b := s.substr(colon + 1)
		return b if b.begins_with("mixamorig_") else ""
	var slash := s.rfind("/")
	var tail := s.substr(slash + 1) if slash != -1 else s
	return tail if tail.begins_with("mixamorig_") else ""
