extends Node
## Offline animation baker.
##
## Hand-rolled local-space retargeting fails because different Mixamo character
## GLBs bake their own rest orientation (Soldier's hips rest is a 180 deg flip,
## the clip rig's is identity), so a local delta tips the body over. The fix is to
## retarget in GLOBAL space:
##
##   clip_global(b) = clip_global(parent) * clip_local(b)
##   target_global(b) = char_rest_global(b) * ref_rest_global(b)^-1 * clip_global(b)
##   new_local(b)     = char_rest_global(parent)^-1 * target_global(b)
##
## This is exact regardless of how the character's rest pose is oriented, and it
## needs no per-frame work at runtime because the result is baked to disk once.
##
## Usage: godot --headless --path . res://scenes/dev_bake_anims.tscn -- --char=Soldier

const AL_PATH := "res://scripts/character/anim_library.gd"
const FPS := 30
const OUT_DIR := "res://assets/characters/baked"
var CLIP_FILE: Dictionary = {}

var _char_name := "Michelle"
## True = copy clip local rotations verbatim (correct when rest poses match).
var DIRECT := true

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--char="):
			_char_name = a.trim_prefix("--char=")
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_bake()
	get_tree().quit()

func _bake() -> void:
	var AL = load(AL_PATH)
	var lib: AnimationLibrary = AL.build()
	AL.apply_loops(lib)
	for fb in AL.CLIPS:
		CLIP_FILE[fb] = AL.CLIPS[fb]

	var base: Node = (load("res://assets/characters/real/%s.glb" % _char_name) as PackedScene).instantiate()
	add_child(base)
	var sk: Skeleton3D = base.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = base.find_children("*", "AnimationPlayer", true, false)[0]
	var sk_path: String = str(base.get_path_to(sk))
	# The AnimationPlayer's root_node is "..", i.e. the character root.
	var ap_root: Node = base.get_node(ap.root_node)

	# --- character rest globals -------------------------------------------
	var char_rest_global: Dictionary = {}
	var char_rest_local: Dictionary = {}
	var char_parent: Dictionary = {}
	for i in sk.get_bone_count():
		var bn: String = sk.get_bone_name(i)
		char_rest_global[bn] = sk.get_bone_global_rest(i).basis.get_rotation_quaternion()
		char_rest_local[bn] = sk.get_bone_rest(i).basis.get_rotation_quaternion()
		var p: int = sk.get_bone_parent(i)
		char_parent[bn] = sk.get_bone_name(p) if p >= 0 else ""

	# --- reference rest globals from a clip GLB ---------------------------
	var ref_rest_global: Dictionary = {}
	var ref_rest_local: Dictionary = {}
	var ref_parent: Dictionary = {}
	var order: Array[String] = []
	_capture_ref(ref_rest_global, ref_rest_local, ref_parent, order)
	if order.is_empty():
		print("[BAKE] FATAL: no reference rig")
		return

	var out := AnimationLibrary.new()
	var n_ok := 0
	for clip in lib.get_animation_list():
		var src: Animation = lib.get_animation(clip)
		# Re-read the reference rest for THIS clip.
		var clip_probe: String = ""
		for fb in CLIP_FILE:
			if CLIP_FILE[fb] == clip:
				clip_probe = "res://assets/characters/animlib/%s.glb" % fb
				break
		if clip_probe != "" and ResourceLoader.exists(clip_probe):
			ref_rest_global.clear()
			ref_rest_local.clear()
			ref_parent.clear()
			order.clear()
			_capture_ref_from(clip_probe, ref_rest_global, ref_rest_local, ref_parent, order)
		var baked := Animation.new()
		baked.length = src.length
		baked.step = 1.0 / float(FPS)
		if src.loop_mode != Animation.LOOP_NONE:
			baked.loop_mode = src.loop_mode

		# Which bones actually move in this clip.
		var rot_tracks: Dictionary = {}   # bone -> track index in src
		var pos_tracks: Dictionary = {}
		for t in src.get_track_count():
			var bone: String = AL._bone_from_path(src.track_get_path(t))
			if bone == "":
				continue
			if src.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				rot_tracks[bone] = t
			elif src.track_get_type(t) == Animation.TYPE_POSITION_3D:
				pos_tracks[bone] = t

		var bones: Array[String] = []
		for b in order:
			if char_rest_global.has(b):
				bones.append(b)
		if bones.is_empty():
			continue

		var n_frames: int = maxi(2, int(ceil(src.length * FPS)) + 1)
		# bone -> Array[Quaternion] sampled locals
		var samples: Dictionary = {}
		for b in bones:
			samples[b] = []

		for f in n_frames:
			var t: float = minf(float(f) / float(FPS), src.length)
			for b in bones:
				# The hips are the root bone: their rest orientation is what holds the
				# body upright and is baked per-character (Soldier even carries a 180 deg
				# flip). Transferring the clip's hips rotation on top of that tips clips
				# with heavy root motion (sprint, block, death) onto their side, so the
				# hips keep the character rest and motion is driven from the spine down.
				# Root lean is re-applied at runtime from gameplay state instead.
				# Local-frame delta: both rests and the clip value live in the bone's own
				# parent frame, so this stays consistent no matter what the hips are
				# doing. Untracked bones fall back to the reference rest, which keeps
				# them at their natural pose instead of collapsing onto the parent
				# (that collapse is what produced T-posed arms and fingers).
				var clip_loc: Quaternion = ref_rest_local.get(b, Quaternion.IDENTITY)
				if rot_tracks.has(b):
					clip_loc = _sample_rot(src, rot_tracks[b], t)
				if b == "mixamorig_Hips":
					samples[b].append(char_rest_local[b])
					continue
				var ref_loc: Quaternion = ref_rest_local.get(b, Quaternion.IDENTITY)
				var delta: Quaternion = (ref_loc.inverse() * clip_loc).normalized()
				samples[b].append((char_rest_local[b] * delta).normalized())

		# write rotation tracks
		for b in bones:
			var tr: int = baked.add_track(Animation.TYPE_ROTATION_3D)
			baked.track_set_path(tr, NodePath("%s:%s" % [sk_path, b]))
			baked.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
			var vals: Array = samples[b]
			for f in n_frames:
				baked.rotation_track_insert_key(tr, float(f) / float(FPS), vals[f])

		# hips translation, rebased onto the character's rest so the body stays seated
		var hips_idx: int = sk.find_bone("mixamorig_Hips")
		if hips_idx >= 0:
			var hips_rest: Vector3 = sk.get_bone_rest(hips_idx).origin
			var hips_track: int = -1
			if pos_tracks.has("mixamorig_Hips"):
				hips_track = pos_tracks["mixamorig_Hips"]
			var tr := baked.add_track(Animation.TYPE_POSITION_3D)
			baked.track_set_path(tr, NodePath("%s:mixamorig_Hips" % sk_path))
			var base_y := 0.0
			if hips_track >= 0 and src.track_get_key_count(hips_track) > 0:
				base_y = (src.track_get_key_value(hips_track, 0) as Vector3).y
			for f in n_frames:
				var t: float = minf(float(f) / float(FPS), src.length)
				var dy := 0.0
				if hips_track >= 0 and src.track_get_key_count(hips_track) > 0:
					dy = (_sample_vec(src, hips_track, t).y - base_y)
				baked.position_track_insert_key(tr, float(f) / float(FPS),
					Vector3(hips_rest.x, hips_rest.y + dy, hips_rest.z))

		out.add_animation(clip, baked)
		n_ok += 1

	print("[BAKE] ", _char_name, " baked=", n_ok, " clips")
	var res_path := "%s/%s.tres" % [OUT_DIR, _char_name]
	ResourceSaver.save(out, res_path)
	print("[BAKE] saved ", res_path)

func _capture_ref_from(path: String, glob: Dictionary, loc: Dictionary, parent: Dictionary, order: Array[String]) -> void:
	var inst: Node = (load(path) as PackedScene).instantiate()
	var root: Node = inst.get_node_or_null("RootNode")
	if root != null:
		_walk(root, Quaternion.IDENTITY, "", glob, loc, parent, order)
	inst.free()

func _capture_ref(glob: Dictionary, loc: Dictionary, parent: Dictionary, order: Array[String]) -> void:
	var probe := "res://assets/characters/animlib/Run.glb"
	var inst: Node = (load(probe) as PackedScene).instantiate()
	var root: Node = inst.get_node_or_null("RootNode")
	if root != null:
		_walk(root, Quaternion.IDENTITY, "", glob, loc, parent, order)
	inst.free()

func _walk(n: Node, parent_g: Quaternion, parent_name: String, glob: Dictionary, loc: Dictionary, parent: Dictionary, order: Array[String]) -> void:
	var g := parent_g
	var nm := String(n.name)
	if n is Node3D:
		var l: Quaternion = (n as Node3D).transform.basis.get_rotation_quaternion()
		g = (parent_g * l).normalized()
		if nm.begins_with("mixamorig_"):
			loc[nm] = l
	if nm.begins_with("mixamorig_"):
		glob[nm] = g
		parent[nm] = parent_name
		order.append(nm)
	for c in n.get_children():
		_walk(c, g, nm if nm.begins_with("mixamorig_") else parent_name, glob, loc, parent, order)

func _sample_rot(a: Animation, track: int, t: float) -> Quaternion:
	var n: int = a.track_get_key_count(track)
	if n == 0:
		return Quaternion.IDENTITY
	if n == 1 or t <= a.track_get_key_time(track, 0):
		return a.track_get_key_value(track, 0)
	if t >= a.track_get_key_time(track, n - 1):
		return a.track_get_key_value(track, n - 1)
	var lo := 0
	for i in n - 1:
		if a.track_get_key_time(track, i) <= t:
			lo = i
	var t0: float = a.track_get_key_time(track, lo)
	var t1: float = a.track_get_key_time(track, lo + 1)
	var w: float = 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
	return (a.track_get_key_value(track, lo) as Quaternion).slerp(a.track_get_key_value(track, lo + 1), w)

func _sample_vec(a: Animation, track: int, t: float) -> Vector3:
	var n: int = a.track_get_key_count(track)
	if n == 0:
		return Vector3.ZERO
	if n == 1 or t <= a.track_get_key_time(track, 0):
		return a.track_get_key_value(track, 0)
	if t >= a.track_get_key_time(track, n - 1):
		return a.track_get_key_value(track, n - 1)
	var lo := 0
	for i in n - 1:
		if a.track_get_key_time(track, i) <= t:
			lo = i
	var t0: float = a.track_get_key_time(track, lo)
	var t1: float = a.track_get_key_time(track, lo + 1)
	var w: float = 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
	return (a.track_get_key_value(track, lo) as Vector3).lerp(a.track_get_key_value(track, lo + 1), w)
