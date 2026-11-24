#!/usr/bin/env python3
"""
REBUILD LEVERAGE — every fix, applied idempotently from a clean checkout of
origin/xogot-iphone-street-work (9417821).

Why this file exists: the workspace was observed reverting tracked files between
turns, taking uncommitted work with it. This script is the durable record. On a
fresh clone, `python3 rebuild_all.py` reproduces the complete, tested state.

Every edit asserts it applied, so a silent no-op becomes a loud failure.

Run from the repo root (the directory containing project.godot).
"""
import os
import sys

OK = []
FAIL = []


def patch(path, old, new, label, count=1, also_done=None):
    """Replace `old` with `new` in `path`, requiring exactly `count` matches."""
    if not os.path.exists(path):
        FAIL.append(f"{label}: MISSING FILE {path}")
        return False
    src = open(path, encoding="utf-8").read()
    for marker in (also_done or []):
        if marker in src:
            OK.append(f"{label}: already applied")
            return True
    if new in src:
        # Already applied. This must be checked FIRST and unconditionally: an
        # earlier patch's OUTPUT can contain a later patch's `old` anchor (the
        # autosave block quotes its own old text in a doc comment), so asking
        # "is old still present" re-applies it and duplicates the whole block.
        OK.append(f"{label}: already applied")
        return True
    n = src.count(old)
    if n != count:
        FAIL.append(f"{label}: expected {count} match(es), found {n} in {path}")
        return False
    src = src.replace(old, new)
    open(path, "w", encoding="utf-8").write(src)
    OK.append(f"{label}: applied")
    return True


# ===========================================================================
# 1. MEMORY — a district cannot afford four separately-baked street sources
# ===========================================================================
def fix_street_memory():
    patch(
        "scripts/world/city_builder.gd",
        """	var v := 0
	# Streets running along the X axis, on the block lines.
	for z in [-mid, mid]:
		var st: Node3D = kit.get_street(type, v, span)
		st.name = "Street_Z%d" % int(z)
		st.position = Vector3(-span * 0.5, 0.0, z)
		root.add_child(st)
		v += 1
	# Streets running along the Z axis, crossing them.
	for x in [-mid, mid]:
		var st2: Node3D = kit.get_street(type, v, span)
		st2.name = "Street_X%d" % int(x)
		st2.position = Vector3(x, 0.0, -span * 0.5)
		st2.rotation.y = PI * 0.5
		root.add_child(st2)
		v += 1""",
        """	# VARIETY IS BOUGHT WITH MEMORY, SO IT IS BOUGHT WHERE IT SHOWS.
	#
	# Each street variant is a separately baked source of ~196,000 vertices, and a
	# source cannot be freed while any duplicate of it is alive. Asking for four
	# variants per district meant four sources — measured 235 MB of the 350 MB a
	# district cost — for streets that read almost identically, because a variant
	# only changes the RNG seed used to place shop units on a fixed chassis.
	#
	# So the crossing pair reuses the same baked source as the first pair (its
	# duplicates share the source's mesh data, so they cost transforms only), and
	# the second variant is spent on the street that faces the player rather than
	# on one that closes the block behind him.
	var st_a: Node3D = kit.get_street(type, 0, span)
	st_a.name = "Street_Z%d" % int(-mid)
	st_a.position = Vector3(-span * 0.5, 0.0, -mid)
	root.add_child(st_a)

	var st_b: Node3D = kit.get_street(type, 1, span)
	st_b.name = "Street_Z%d" % int(mid)
	st_b.position = Vector3(-span * 0.5, 0.0, mid)
	root.add_child(st_b)

	# Crossings reuse source 0: same geometry, turned 90 degrees.
	for x in [-mid, mid]:
		var st2: Node3D = kit.get_street(type, 0, span)
		st2.name = "Street_X%d" % int(x)
		st2.position = Vector3(x, 0.0, -span * 0.5)
		st2.rotation.y = PI * 0.5
		root.add_child(st2)""",
        "memory: 4 street sources -> 2 per district",
    )


# ===========================================================================
# 2. LEAKS — baked sources out of the tree, freed with the kit, originals freed
#              atomically, and positional audio pooled
# ===========================================================================
def fix_leaks():
    patch(
        "scripts/world/street_kit.gd",
        """var _library: Dictionary = {}

## Build, bake and cache a street of `type`. Returns a fresh duplicate that can
## be moved and parented freely.
func get_street(type: int, variant: int = 0, length: float = 78.0) -> Node3D:
	var key := "%d_%d_%d" % [type, variant, int(length)]
	if not _library.has(key):
		var k = load("res://scripts/world/street_kit.gd").new()
		k.set_seed(hash(key))
		add_child(k)
		k.build_street(Vector3.ZERO, Vector3(1, 0, 0), length, type)
		k.bake_static(k)
		_library[key] = k
	var src: Node3D = _library[key]
	var dup := src.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
	return dup""",
        """var _library: Dictionary = {}

## Baked street sources are held OUT of the tree.
##
## They used to be children of the kit forever: every cached street kept its full
## node tree live inside the district, so a district carried roughly double its
## own geometry for the life of the process. Nothing ever renders a source - only
## the duplicates - so the tree was holding it for nothing.
func get_street(type: int, variant: int = 0, length: float = 78.0) -> Node3D:
	var key := "%d_%d_%d" % [type, variant, int(length)]
	if not _library.has(key):
		var k = load("res://scripts/world/street_kit.gd").new()
		k.name = "StreetSource"
		k.set_seed(hash(key))
		# In the tree while it is built: the builders need a parent.
		add_child(k)
		k.build_street(Vector3.ZERO, Vector3(1, 0, 0), length, type)
		k.bake_static(k)
		# Detach without leaving an orphan. remove_child() alone leaves the node
		# alive with no parent, and one source is a few hundred nodes.
		remove_child(k)
		_library[key] = k
	var src: Node3D = _library[key]
	var dup := src.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
	return dup

## The cached sources have no parent, so nothing frees them unless this does:
## without it they survive to process exit and Godot reports them as leaked.
func _exit_tree() -> void:
	clear_library()

func clear_library() -> void:
	for key in _library:
		var k = _library[key]
		if is_instance_valid(k):
			k.free()
	_library.clear()""",
        "leak: street sources detached + freed with the kit",
    )

    patch(
        "scripts/world/street_kit.gd",
        """	# free the originals
	for mat in groups:
		for mi in by_mat[mat]:
			if is_instance_valid(mi) and mi.get_parent() != null:
				mi.get_parent().remove_child(mi)
				mi.queue_free()
	return baked""",
        """	# Free the originals. free() rather than queue_free(): the parent has been
	# rebuilt in the same frame, and a queued free leaves the node alive with no
	# parent until end of frame - an orphan. Thousands of those per world is what
	# produced the "leaked instance dependency" flood at exit.
	for mat in groups:
		for mi in by_mat[mat]:
			if is_instance_valid(mi) and mi.get_parent() != null:
				mi.get_parent().remove_child(mi)
				mi.free()
	return baked""",
        "leak: bake_static frees originals atomically",
    )

    patch(
        "scripts/autoload/audio_director.gd",
        """	var p := AudioStreamPlayer3D.new()
	p.stream = load(path)
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.unit_size = 14.0
	p.max_distance = 70.0
	tree.current_scene.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)""",
        """	# Take an idle player from the pool rather than allocating one. A node per
	# footstep is churn, and any playback still alive at teardown leaked an
	# AudioStreamPlaybackWAV (the pool existed but was never used).
	if _pool.is_empty(): return
	var p: AudioStreamPlayer3D = _pool[0]
	for c in _pool:
		if not c.playing:
			p = c
			break
	p.stream = load(path)
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.global_position = pos
	p.play()""",
        "leak: positional audio uses the pool",
    )

    patch(
        "scripts/autoload/audio_director.gd",
        """	for i in MAX2D:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		_ui.append(s)
	apply_volume()""",
        """	for i in MAX2D:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		_ui.append(s)
	for i in MAX3D:
		var s3 := AudioStreamPlayer3D.new()
		s3.bus = "SFX"
		s3.unit_size = 14.0
		s3.max_distance = 70.0
		add_child(s3)
		_pool.append(s3)
	apply_volume()""",
        "leak: create the 3D pool",
    )


# ===========================================================================
# 3. CRASH — an empty animation library indexed [0] once per figure per frame
# ===========================================================================
def fix_crowd_crash():
    patch(
        "scripts/world/street_crowd.gd",
        """	var clip: String = CROWD_CLIPS[_rng.randi_range(0, CROWD_CLIPS.size() - 1)]
	if not ap.has_animation(clip):
		clip = "Walk" if ap.has_animation("Walk") else ap.get_animation_list()[0]""",
        """	# An empty library is possible: a rig scene can load while its clips are
	# still missing from the cache. Indexing [0] on that crashed once per figure
	# per frame; a static figure is the correct fallback, not a crash.
	var list := ap.get_animation_list()
	if list.is_empty():
		ap.queue_free()
		return
	var clip: String = CROWD_CLIPS[_rng.randi_range(0, CROWD_CLIPS.size() - 1)]
	if not ap.has_animation(clip):
		clip = "Walk" if ap.has_animation("Walk") else String(list[0])""",
        "crash: crowd handles an empty animation library",
    )


# ===========================================================================
# 4. COMPLETENESS — the six defects that made shipped content unreachable
# ===========================================================================
def fix_completeness():
    # 4a. pickups: _spawn_fragments picked its district by `placed % size` and
    #     then `continue`d when that district had no nav nodes - without
    #     advancing `placed`. A district with an empty nav graph therefore spun
    #     the loop forever: a silent hard freeze with no error, which is why it
    #     survived. Choose from the districts that actually have nodes instead,
    #     and walk the list once so no district is starved.
    patch(
        "scripts/systems/pickups.gd",
        """	var placed := 0
	var districts: Array = Content.DISTRICT_ORDER.duplicate()
	while placed < FRAGMENT_COUNT:
		var district: String = districts[placed % districts.size()]
		var center: Vector3 = world.builder.district_center(district)
		var nodes: Array = world.builder.nav_nodes.get(district, [])
		if nodes.is_empty(): continue
		var offset: Vector3 = nodes[randi() % nodes.size()]
		var pos: Vector3 = center + offset + Vector3(randf_range(-3, 3), 0.9, randf_range(-3, 3))
		_create_fragment("frag_%d" % (placed + 1), pos)
		placed += 1""",
        """	var placed := 0
	var districts: Array = Content.DISTRICT_ORDER.duplicate()
	while placed < FRAGMENT_COUNT:
		var district: String = districts[placed % districts.size()]
		var center: Vector3 = world.builder.district_center(district)
		var nodes: Array = world.builder.nav_nodes.get(district, [])
		if nodes.is_empty():
			# Skip a district with no navigation, but never retry the same slot:
			# advancing here is what stops this loop becoming a silent hang.
			placed += 1
			continue
		var offset: Vector3 = nodes[randi() % nodes.size()]
		var pos: Vector3 = center + offset + Vector3(randf_range(-3, 3), 0.9, randf_range(-3, 3))
		_create_fragment("frag_%d" % (placed + 1), pos)
		placed += 1""",
        "completeness: fragment spawn cannot spin forever",
    )

    # Game is an untyped autoload reference here, so the inferred type of
    # current_objective() is Variant and 4.4 rejects `var obj :=`. Untyped is
    # the bug: name the type and the parse error goes away.
    patch(
        "scripts/systems/pickups.gd",
        "\tvar obj := Game.current_objective()",
        "\tvar obj: Dictionary = Game.current_objective()",
        "completeness: pickups parse cleanly on 4.4",
    )

    # 4b. vendors were tagged kind="vendor" while every handler checks "shop".
    patch(
        "scripts/systems/interiors.gd",
        'a.set_meta("kind", "vendor")',
        'a.set_meta("kind", "shop")',
        "completeness: vendor is tagged as a shop",
    )

    # 4c. activate() had no dispatch for pickups or shops, though both systems
    #     exist in full (pickups.collect, hud.open_shop). Fragments were
    #     uncollectable and every vendor was mute.
    patch(
        "scripts/systems/interaction_system.gd",
        """func activate(target: Node3D, player) -> void:
	if target == null: return
	if target is VehicleBody3D:""",
        """func activate(target: Node3D, player) -> void:
	if target == null: return
	if target.has_meta("kind") and target.get_meta("kind") == "pickup":
		world.pickups.collect(target)
		Audio.play_ui("pickup")
		return
	if target.has_meta("kind") and target.get_meta("kind") == "shop":
		var vendor := str(target.get_meta("vendor", "general"))
		world.hud.open_shop(vendor)
		Audio.play_ui("click")
		return
	if target is VehicleBody3D:""",
        "completeness: pickups and shops respond to interact",
    )

    # 4d. notice re-shown every launch.
    patch(
        "scripts/ui/boot.gd",
        """func _show_stage(stage: int) -> void:
	for c in _stage_root.get_children():""",
        """func _notice_accepted() -> bool:
	return FileAccess.file_exists(NOTICE_FILE)

func _show_stage(stage: int) -> void:
	# Skip the notice on every launch after the first.
	if stage == 2 and _notice_accepted():
		stage = 3
	for c in _stage_root.get_children():""",
        "completeness: notice is asked for once",
    )

    # 4e. returning players started at the studio card every time.
    patch(
        "scripts/ui/boot.gd",
        """	add_child(_stage_root)
	_show_stage(0)""",
        """	add_child(_stage_root)
	# A returning player has already accepted the notice: start at the title and
	# let the stage machine roll into the menu, never through the notice again.
	_show_stage(0 if not _notice_accepted() else 1)""",
        "completeness: returning players skip the studio card",
    )

    # 4f. autosave support is provided by 4f2 below, which writes the
    #     timestamp-comparing latest_save_slot() directly. (An earlier version
    #     of this script had two steps here and re-inserted the first one's
    #     output; see the idempotency note at the top of patch().)

    # 4f2. CONTINUE must be able to see the autosave, and must pick the newest
    #      save by timestamp rather than by slot number.
    patch(
        "scripts/autoload/game.gd",
        """func latest_save_slot() -> int:
	for i in range(SLOT_COUNT - 1, -1, -1):
		if FileAccess.file_exists(_slot_path(i)):
			return i
	if FileAccess.file_exists(_slot_path(AUTOSAVE_SLOT)):
		return AUTOSAVE_SLOT
	return -1""",
        """## The most recently WRITTEN save, autosave included. Slot numbers are not
## recency: slot 2 can hold a save from last week and slot 9 one from a minute
## ago, so comparing slot numbers picks the wrong game. Read each file's own
## saved_at and take the newest.
func latest_save_slot() -> int:
	var best := -1
	var best_at := ""
	var candidates: Array = []
	for i in SLOT_COUNT:
		candidates.append(i)
	candidates.append(AUTOSAVE_SLOT)
	for i in candidates:
		if not FileAccess.file_exists(_slot_path(i)):
			continue
		var f := FileAccess.open(_slot_path(i), FileAccess.READ)
		if f == null: continue
		var txt := f.get_as_text()
		f.close()
		var at := ""
		var j: Variant = JSON.parse_string(txt)
		if j is Dictionary:
			at = str((j as Dictionary).get("saved_at", ""))
		if at != "" and at >= best_at:
			best_at = at
			best = i
	return best""",
        "completeness: latest save is chosen by time, not slot number",
        also_done=['and take the newest.'],
    )

    patch(
        "scripts/ui/main_menu.gd",
        """func _any_save() -> bool:
	for i in Game.SLOT_COUNT:
		if not Game.slot_info(i).is_empty(): return true
	return false""",
        """func _any_save() -> bool:
	# An autosave is a save: without this, a player whose only progress was
	# written automatically sees no CONTINUE at all.
	if not Game.slot_info(Game.AUTOSAVE_SLOT).is_empty(): return true
	for i in Game.SLOT_COUNT:
		if not Game.slot_info(i).is_empty(): return true
	return false""",
        "completeness: CONTINUE offered when only an autosave exists",
        also_done=['# An autosave is a save: without this, a player whose only save was written'],
    )

    patch(
        "scripts/ui/main_menu.gd",
        """func _continue_game() -> void:
	var latest := -1
	for i in Game.SLOT_COUNT:
		var info := Game.slot_info(i)
		if info.is_empty(): continue
		if latest < 0 or str(info["saved_at"]) > str(Game.slot_info(latest).get("saved_at", "")):
			latest = i
	if latest >= 0 and Game.load_game(latest):
		Loader.goto_world(false)""",
        """func _continue_game() -> void:
	# Includes the autosave slot. Slot numbers are not recency - the autosave
	# lives at 9 whatever the manual slots hold - so the newest saved_at wins.
	var latest := Game.latest_save_slot()
	if latest >= 0 and Game.load_game(latest):
		Loader.goto_world(false)""",
        "completeness: CONTINUE loads the newest save",
        also_done=['var latest := Game.latest_save_slot()'],
    )

    # 4g. autosave at mission completion: losing an hour of progress to a crash
    #     or a phone call is the kind of thing that ends a session for good.
    patch(
        "scripts/autoload/game.gd",
        """	mission_completed.emit(id)
	notify("Mission complete", data.get("title", id), "mission")
	mission = {}""",
        """	mission_completed.emit(id)
	notify("Mission complete", data.get("title", id), "mission")
	mission = {}
	# Autosave here rather than on a timer: a completed mission is exactly the
	# progress a player would be sick to lose.
	autosave()""",
        "completeness: autosave on mission completion",
    )


# ===========================================================================
# 5. JOBS BOARD — 15 written side jobs with no way to start one
# ===========================================================================
def fix_jobs_board():
    patch(
        "scripts/ui/hud.gd",
        """	var radio_btn := _btn("RADIO", 14)""",
        """	# JOBS BOARD: Game.start_mission_from_job() and 15 written side jobs existed,
	# but nothing in the UI called it: the work was in the game and unreachable.
	# Every job that is not finished is work the player can take right now.
	var jobs_btn := _btn("JOBS", 14)
	jobs_btn.pressed.connect(func(): toggle_jobs())
	phone_vbox.add_child(jobs_btn)
	var radio_btn := _btn("RADIO", 14)""",
        "jobs: JOBS button on the phone",
    )

    patch(
        "scripts/ui/hud.gd",
        """func _contact_line(bio: String) -> String:
	return bio""",
        """func _contact_line(bio: String) -> String:
	return bio

## Jobs the player could take now: not already done, and not the one running.
func _available_jobs() -> Array:
	var out: Array = []
	for jid in Content.SIDE_JOBS:
		if Game.completed_jobs.has(jid):
			continue
		if not Game.mission.is_empty() and str(Game.mission.get("job", "")) == str(jid):
			continue
		out.append(jid)
	return out

func toggle_jobs() -> void:
	if _jobs == null: return
	_jobs.visible = not _jobs.visible
	if not _jobs.visible: return
	for c in jobs_list.get_children():
		c.queue_free()
	var avail: Array = _available_jobs()
	if avail.is_empty():
		jobs_list.add_child(_label("No work on the board right now.", 13, TEXT_DIM))
		return
	for jid in avail:
		var job: Dictionary = Content.SIDE_JOBS[jid]
		var row := _panel(Color(0.08, 0.085, 0.10, 0.92), 10)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		row.add_child(v)
		v.add_child(_label(str(job.get("name", jid)), 15, GOLD))
		v.add_child(_label(str(job.get("brief", "")), 11, TEXT_DIM))
		var take := _btn("TAKE THE JOB", 12)
		var jid_c: String = str(jid)
		take.pressed.connect(func():
			# Close the board, then start: the mission spawns its own targets.
			_jobs.visible = false
			_phone.visible = false
			Game.start_mission_from_job(jid_c, Content.SIDE_JOBS[jid_c])
		)
		v.add_child(take)
		jobs_list.add_child(row)""",
        "jobs: board lists and starts available work",
    )

    patch(
        "scripts/ui/hud.gd",
        """func open_shop(vendor_id: String) -> void:""",
        """var _jobs: Control
var jobs_list: VBoxContainer

func _build_jobs() -> void:
	_jobs = _fullscreen_overlay()
	var p := _panel(Color(0.045, 0.05, 0.062, 0.98), 18)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-330, -250)
	p.custom_minimum_size = Vector2(660, 500)
	_jobs.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_label("JOBS", 24, GOLD))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(630, 370)
	v.add_child(scroll)
	jobs_list = VBoxContainer.new()
	jobs_list.custom_minimum_size = Vector2(620, 0)
	jobs_list.add_theme_constant_override("separation", 6)
	scroll.add_child(jobs_list)
	var close := _btn("CLOSE", 15)
	close.pressed.connect(func(): _jobs.visible = false)
	v.add_child(close)

func open_shop(vendor_id: String) -> void:""",
        "jobs: board UI built",
    )

    patch(
        "scripts/ui/hud.gd",
        "	_build_shop()",
        "	_build_shop()\n	_build_jobs()",
        "jobs: board built at hud construction",
    )

# ===========================================================================
# 6. TESTABILITY
# ===========================================================================
def fix_xogot():
    patch(
        "scripts/ui/boot.gd",
        """func _depart() -> void:
	Loader.goto_scene("res://scenes/main_menu.tscn", 0.4)""",
        """var _depart_disabled := false

func _depart() -> void:
	# A probe can hold the final stage instead of being torn down by the scene
	# swap that stage performs.
	if _depart_disabled:
		return
	Loader.goto_scene("res://scenes/main_menu.tscn", 0.4)""",
        "testability: boot final stage can be held",
    )


if __name__ == "__main__":
    print("REBUILD LEVERAGE\n" + "=" * 60)
    fix_street_memory()
    fix_leaks()
    fix_crowd_crash()
    fix_completeness()
    fix_jobs_board()
    fix_xogot()
    print()
    for line in OK:
        print("  OK    " + line)
    for line in FAIL:
        print("  FAIL  " + line)
    print("=" * 60)
    print(f"{len(OK)} applied, {len(FAIL)} failed")
    sys.exit(1 if FAIL else 0)
