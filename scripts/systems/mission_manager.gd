extends Node
## MISSION MANAGER — drives objective progression against the live world.
## Objective types: reach | talk | collect | fight | escape | drive | steal | choice
## The manager is the only thing that calls Game.advance_mission().

var world: Node3D
var builder: Node = null
var _tick := 0.0
var _fight_targets: Array = []
var _choice_shown := false

func setup(w: Node3D) -> void:
	world = w
	builder = w.builder
	Game.mission_started.connect(_on_mission_started)
	Game.mission_objective_changed.connect(_on_objective_changed)
	# Kick off the opening mission for a fresh run.
	if Game.mission.is_empty() and Game.completed_missions.is_empty():
		Game.start_mission("homecoming")

func _on_mission_started(id: String) -> void:
	Audio.play_stinger("mission")
	_choice_shown = false
	_fight_targets.clear()

func _on_objective_changed(index: int, obj: Dictionary) -> void:
	_fight_targets.clear()
	_choice_shown = false
	if obj.is_empty(): return
	Game.notify("Objective", _text(obj), "objective")
	# Spawn opposition / collectibles for fight objectives.
	if obj.get("type", "") == "fight":
		var center: Vector3 = world.player.global_position
		var count := int(obj.get("count", 1))
		if obj.get("target", "") == "kola":
			_fight_targets = world.npcs.spawn_squad(center + Vector3(6, 0, 6), 3, 80.0, 8.0)
			Game.set_flag("kola_fight")
		elif obj.get("target", "") == "okafor":
			_fight_targets = world.npcs.spawn_squad(center + Vector3(5, 0, 5), 3, 110.0, 11.0)
		else:
			_fight_targets = world.npcs.spawn_squad(center + Vector3(5, 0, 4), count, 70.0, 7.0)

func _text(obj: Dictionary) -> String:
	return str(obj.get("text", ""))

func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0: return
	_tick = 0.25
	if Game.mission.is_empty(): 
		_try_next_story_beat()
		return
	var obj := Game.current_objective()
	if obj.is_empty(): return
	match str(obj.get("type", "")):
		"reach": _check_reach(obj)
		"talk": _check_talk(obj)
		"collect": pass  # pickups.gd reports progress
		"fight": _check_fight(obj)
		"escape": _check_escape(obj)
		"drive": _check_drive(obj)
		"steal": _check_steal(obj)
		"choice": _check_choice(obj)
		"intimidate": _check_intimidate(obj)
		"escort": _check_escort(obj)
		"tail": _check_tail(obj)
		"deliver": _check_deliver(obj)
		"defend": _check_defend(obj)
		"survive": _check_survive(obj)
		"bounty": _check_bounty(obj)

func _check_reach(obj: Dictionary) -> void:
	var target: String = str(obj.get("target", ""))
	var pos := _target_position(target)
	if pos == Vector3.INF: return
	if world.player.global_position.distance_to(pos) < 7.0:
		Game.advance_mission()

func _check_talk(obj: Dictionary) -> void:
	# Talking is driven by interaction.gd -> missions.report_talk()
	pass

func report_talk(cid: String) -> void:
	if Game.mission.is_empty(): return
	var obj := Game.current_objective()
	var t := str(obj.get("type", ""))
	if (t == "talk" or t == "intimidate") and str(obj.get("target", "")) == cid:
		Game.advance_mission()
		Audio.play_ui("confirm")

## A conversation resolved with an outcome. Missions can require a specific one:
##   {"type":"talk", "target":"ngozi", "needs_outcome":"lead_strong"}
## This is what makes the four dialogue approaches matter to the plot rather
## than only to a trust number.
func report_conversation(cid: String, outcome: String) -> void:
	if Game.mission.is_empty(): return
	var obj := Game.current_objective()
	if str(obj.get("target", "")) != cid: return
	var needs := str(obj.get("needs_outcome", ""))
	if needs != "" and needs != outcome:
		Game.notify("NOT ENOUGH", "You need a better answer than that.", "error")
		return
	if str(obj.get("type", "")) == "talk" or str(obj.get("type", "")) == "intimidate":
		Game.advance_mission()
		Audio.play_ui("confirm")

func _check_fight(obj: Dictionary) -> void:
	var alive := 0
	for t in _fight_targets:
		if is_instance_valid(t) and not t.is_dead: alive += 1
	if _fight_targets.size() > 0 and alive == 0:
		Game.advance_mission()

func _check_escape(_obj: Dictionary) -> void:
	if Game.wanted == 0:
		Game.advance_mission()

func _check_drive(_obj: Dictionary) -> void:
	if world.player.vehicle != null and world.player.vehicle.linear_velocity.length() > 4.0:
		Game.add_mission_progress(1)

func _check_steal(obj: Dictionary) -> void:
	var pos := _target_position(str(obj.get("target", "")))
	if pos == Vector3.INF: return
	if world.player.global_position.distance_to(pos) < 6.0:
		Game.advance_mission()

func _check_choice(obj: Dictionary) -> void:
	if _choice_shown: return
	_choice_shown = true
	var choices: Array = Game.mission["data"].get("choices", [])
	if choices.is_empty():
		Game.advance_mission()
		return
	world.hud.show_choices(obj.get("text", "Decide"), choices, func(c):
		Game.set_flag(c.get("flag", "choice"))
		if int(c.get("money", 0)) != 0: Game.add_money(int(c["money"]))
		if int(c.get("xp", 0)) != 0: Game.add_xp(int(c["xp"]))
		for f in c.get("trust", {}): Game.add_trust(f, int(c["trust"][f]))
		world.hud.hide_choices()
		Game.advance_mission()
	)

## Intimidate: the target must be talked to while still standing.
func _check_intimidate(_obj: Dictionary) -> void:
	pass   # driven by report_talk, like "talk"

## Escort: an escort actor must survive and stay within range of the player.
var _escort_actor: Node3D = null
func _check_escort(obj: Dictionary) -> void:
	if _escort_actor == null or not is_instance_valid(_escort_actor):
		_escort_actor = _spawn_escort(obj)
		return
	if _escort_actor.get("is_dead") == true:
		Game.fail_mission("The escort didn't make it.")
		return
	var pos := _target_position(str(obj.get("target", "")))
	if pos == Vector3.INF:
		return
	if _escort_actor.global_position.distance_to(pos) < 8.0:
		_escort_actor.queue_free()
		_escort_actor = null
		Game.advance_mission()

func _spawn_escort(_obj: Dictionary) -> Node3D:
	if world.npcs == null:
		return null
	var a = load("res://scripts/npc/actor.gd").new()
	a.setup({"role": "courier", "faction": "family", "health": 80.0})
	a.name = "EscortTarget"
	world.add_child(a)
	a.global_position = world.player.global_position + Vector3(2.0, 0.3, 0.0)
	return a

## Tail: follow without being seen. Fails if the player gets too close.
var _tail_steps := 0
func _check_tail(obj: Dictionary) -> void:
	var pos := _target_position(str(obj.get("target", "")))
	if pos == Vector3.INF:
		return
	var d: float = world.player.global_position.distance_to(pos)
	if d < 6.0:
		Game.fail_mission("You were made.")
		return
	if d < 30.0:
		_tail_steps += 1
		if _tail_steps > 24:                     # six seconds in the sweet spot
			Game.advance_mission()

func _check_deliver(obj: Dictionary) -> void:
	var pos := _target_position(str(obj.get("target", "")))
	if pos == Vector3.INF:
		return
	if world.player.global_position.distance_to(pos) < 6.0:
		Game.advance_mission()

## Defend: hold a spot against waves for a fixed duration.
var _defend_timer := 0.0
var _defend_wave := 0
var _defend_spot := Vector3.INF
func _check_defend(obj: Dictionary) -> void:
	if _defend_spot == Vector3.INF:
		_defend_spot = _target_position(str(obj.get("target", "")))
		if _defend_spot == Vector3.INF:
			_defend_spot = world.player.global_position
	var need := float(obj.get("seconds", 45.0))
	if world.player.global_position.distance_to(_defend_spot) > 18.0:
		return                                   # you left the point; clock stops
	_defend_timer += 0.25
	if _defend_timer >= need:
		_defend_spot = Vector3.INF
		_defend_timer = 0.0
		Game.advance_mission()
		return
	# A new wave every 15 seconds.
	var want_wave: int = int(_defend_timer / 15.0)
	if want_wave > _defend_wave and world.npcs != null:
		_defend_wave = want_wave
		var squad: Array = world.npcs.spawn_squad(_defend_spot + Vector3(12, 0, 0), 3)
		_fight_targets.append_array(squad)

func _check_survive(obj: Dictionary) -> void:
	var need := float(obj.get("seconds", 30.0))
	_defend_timer += 0.25
	if _defend_timer >= need:
		_defend_timer = 0.0
		Game.advance_mission()

func _check_bounty(obj: Dictionary) -> void:
	if _fight_targets.is_empty() and obj.has("_spawned"):
		Game.advance_mission()
		return
	if not obj.has("_spawned"):
		obj["_spawned"] = true
		_spawn_bounty(obj)

func _spawn_bounty(obj: Dictionary) -> void:
	var pos := _target_position(str(obj.get("target", "")))
	if pos == Vector3.INF:
		return
	var id := str(obj.get("archetype", "street_thug"))
	var tier := int(obj.get("tier", 3))
	var a = load("res://scripts/npc/actor.gd").new()
	a.setup({"role": "enforcer", "faction": "crew", "hostile": true,
		"name": str(obj.get("name", id))})
	a.fight_data = Archetypes.make(id, tier)
	world.add_child(a)
	a.global_position = pos + Vector3(1.5, 0.3, 0)
	_fight_targets.append(a)

## Public wrapper so the HUD/minimap can ask where an objective is.
func target_position(target: String) -> Vector3:
	return _target_position(target)

func _target_position(target: String) -> Vector3:
	# Landmarks resolve through the builder; NPCs through the population list.
	for a in world.npcs.named:
		if is_instance_valid(a) and a.npc_id == target:
			return a.global_position
	var district: String = Game.mission.get("data", {}).get("district", Game.current_district)
	for id in Content.INTERIORS:
		if id == target:
			district = Content.INTERIORS[id]["district"]
	var center: Vector3 = builder.district_center(district)
	# Landmark offsets are deterministic in city_builder (_build_landmarks).
	var lm: Array = Content.DISTRICTS[district]["landmarks"]
	var idx := lm.find(target)
	if idx < 0: return Vector3.INF
	var ang := TAU * float(idx) / float(lm.size()) + 0.4
	return center + Vector3(cos(ang) * 30.0, 0, sin(ang) * 30.0)

func _try_next_story_beat() -> void:
	if not Game.completed_missions.has("homecoming"): return
	var m := Game.next_available_mission()
	if m == "": return
	# Only auto-offer when the player is in the right district, as a job marker.
	var d: String = Content.MISSIONS[m]["district"]
	if world.player.global_position.distance_to(builder.district_center(d)) < 55.0:
		world.hud.offer_mission(Content.MISSIONS[m]["title"], func():
			Game.start_mission(m)
		)
