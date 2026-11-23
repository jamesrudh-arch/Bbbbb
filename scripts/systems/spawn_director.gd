extends Node
## SPAWN DIRECTOR — puts the city's content into the world while you walk it.
##
## Three jobs, in priority order:
##   1. Never spawn something the player cannot see or reach.
##   2. Never spawn on top of the player.
##   3. Make the street feel like it reacts to you, not like it is rolling dice.
##
## Street events, ambient crime and police response all route through here so
## there is one place that decides what exists in the world and why.

signal event_started(event: Dictionary, at: Vector3)
signal event_ended(event: Dictionary)
signal crime_reported(at: Vector3)

const EVENT_INTERVAL := [26.0, 52.0]     # seconds between street events
const MIN_PLAYER_DISTANCE := 18.0        # never spawn in the player's lap
const MAX_PLAYER_DISTANCE := 85.0        # and never somewhere they can't see
const DESPAWN_DISTANCE := 220.0
const MAX_ACTIVE_EVENTS := 2
const MAX_ACTIVE_CRIMINALS := 9

var world: Node3D = null
var difficulty: Node = null

var _timer := 12.0
var _active: Array = []                  # [{event, actors, at, age}]
var _rng := RandomNumberGenerator.new()
var _crime: Array = []                   # live criminals spawned by events
var _police_timer := 0.0

func setup(w: Node3D, diff: Node) -> void:
	world = w
	difficulty = diff
	_rng.randomize()
	_timer = _rng.randf_range(EVENT_INTERVAL[0], EVENT_INTERVAL[1])

func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_timer -= delta
	_police_timer -= delta
	_prune()
	if _timer <= 0.0:
		_timer = _rng.randf_range(EVENT_INTERVAL[0], EVENT_INTERVAL[1])
		_try_spawn_event()

	# Police respond to sustained heat, from the nearest edge of the district.
	if Game.wanted >= 2 and _police_timer <= 0.0:
		_police_timer = maxf(9.0, 26.0 - float(Game.wanted) * 4.0)
		_send_police()

# ------------------------------------------------------------------ events
func _try_spawn_event() -> void:
	if _active.size() >= MAX_ACTIVE_EVENTS:
		return
	if world.content_engine == null or difficulty == null:
		return
	var district: String = str(Game.current_district)
	var ev: Dictionary = world.content_engine.pick_event(district, difficulty.threat_level(), _rng)
	if ev.is_empty():
		return
	var spot := _find_spot()
	if spot == Vector3.INF:
		return
	_begin_event(ev, spot)

func _find_spot() -> Vector3:
	var p: Vector3 = world.player.global_position
	for attempt in 12:
		var ang := _rng.randf() * TAU
		var dist := _rng.randf_range(MIN_PLAYER_DISTANCE, MAX_PLAYER_DISTANCE)
		var pos := p + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		if _is_walkable(pos):
			return pos
	return Vector3.INF

func _is_walkable(pos: Vector3) -> bool:
	var space := world.get_world_3d().direct_space_state
	var from := pos + Vector3(0, 6.0, 0)
	var to := pos - Vector3(0, 2.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	return not hit.is_empty()

func _begin_event(ev: Dictionary, at: Vector3) -> void:
	var record := {"event": ev, "at": at, "actors": [], "age": 0.0, "resolved": false}
	var kind := str(ev.get("kind", ""))

	match kind:
		"mugging", "shakedown":
			# A criminal and a victim. The player can intervene or walk past.
			var victim := _spawn_civilian(at + Vector3(_rng.randf_range(-2, 2), 0, _rng.randf_range(-2, 2)))
			var mugger := _spawn_hostile(ev, at + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3)))
			record["actors"] = [victim, mugger]
			record["victim"] = victim
			if victim != null:
				victim.set_meta("fleeing", true)
			if mugger != null and victim != null:
				mugger.ai.begin(victim)
		"chase":
			var runner := _spawn_hostile(ev, at)
			record["actors"] = [runner]
			if runner != null:
				runner.ai.begin(world.player)
		"deal":
			# Two crew, no hostility until the player interferes.
			var a := _spawn_hostile(ev, at)
			var b := _spawn_hostile(ev, at + Vector3(_rng.randf_range(1, 3), 0, _rng.randf_range(1, 3)))
			if a != null: a.hostile = false
			if b != null: b.hostile = false
			record["actors"] = [a, b]
		"raid":
			var squad := []
			var n: int = difficulty.squad_size(3) if difficulty != null else 3
			for i in n:
				var m := _spawn_hostile(ev, at + Vector3(cos(TAU * i / n) * 3.0, 0, sin(TAU * i / n) * 3.0))
				if m != null:
					m.ai.begin(world.player)
					squad.append(m)
			record["actors"] = squad
		"accident":
			var victim2 := _spawn_civilian(at)
			if victim2 != null:
				victim2.set("is_dead", true)
				if victim2.rig != null:
					victim2.rig.play("die")
			record["actors"] = [victim2]
		"race":
			record["actors"] = []
			if world.hud != null:
				world.hud.notify("STREET RACE", "A line is forming on the strip.", "info")
		"fire":
			record["actors"] = []
			if world.hud != null:
				world.hud.notify("FIRE", "Something's burning near you.", "error")
		_:
			record["actors"] = []

	_active.append(record)
	event_started.emit(ev, at)
	if world.hud != null and world.hud.has_method("show_bark"):
		world.hud.show_bark("", str(ev.get("text", "")), at + Vector3(0, 2.0, 0))
	Crash.event("street_event", "%s at %s" % [kind, str(Game.current_district)])

func _spawn_hostile(ev: Dictionary, at: Vector3) -> Node3D:
	if world.npcs == null:
		return null
	var arch := str(ev.get("archetype", "street_thug"))
	if not Archetypes.has_archetype(arch):
		arch = "street_thug"
	var tier: int = difficulty.tier_for_spawn() if difficulty != null else 2
	var a = load("res://scripts/npc/actor.gd").new()
	a.setup({"role": "thug", "faction": "crew", "hostile": true})
	a.fight_data = Archetypes.make(arch, tier)
	world.add_child(a)
	a.global_position = at + Vector3(0, 0.4, 0)
	return a

func _spawn_civilian(at: Vector3) -> Node3D:
	if world.npcs == null:
		return null
	var a = load("res://scripts/npc/actor.gd").new()
	a.setup({"role": "neighbour", "faction": "family", "hostile": false})
	world.add_child(a)
	a.global_position = at + Vector3(0, 0.4, 0)
	return a

# ------------------------------------------------------------------ police
func _send_police() -> void:
	if world.npcs == null:
		return
	var p: Vector3 = world.player.global_position
	var ang := _rng.randf() * TAU
	var at := p + Vector3(cos(ang) * 55.0, 0, sin(ang) * 55.0)
	if not _is_walkable(at):
		return
	var tier: int = difficulty.tier_for_spawn() if difficulty != null else 2
	var n := clampi(Game.wanted, 1, 4)
	for i in n:
		var a = load("res://scripts/npc/actor.gd").new()
		a.setup({"role": "police", "faction": "police", "hostile": true, "name": "CCPD"})
		a.fight_data = Archetypes.make("corporate_sec" if Game.wanted >= 3 else "street_thug", tier)
		a.notice_range = 40.0
		world.add_child(a)
		a.global_position = at + Vector3(cos(TAU * i / n) * 4.0, 0.4, sin(TAU * i / n) * 4.0)
		if a.ai != null:
			a.ai.begin(world.player)
		_crime.append(a)
	crime_reported.emit(p)

# ------------------------------------------------------------------ upkeep
func _prune() -> void:
	var p: Vector3 = world.player.global_position
	for i in range(_active.size() - 1, -1, -1):
		var rec: Dictionary = _active[i]
		rec["age"] = float(rec["age"]) + get_process_delta_time()
		var alive := 0
		for a in rec["actors"]:
			if is_instance_valid(a) and not a.get("is_dead"):
				alive += 1
			if is_instance_valid(a) and a.global_position.distance_to(p) > DESPAWN_DISTANCE:
				a.queue_free()
		var too_far: bool = rec["at"].distance_to(p) > DESPAWN_DISTANCE
		if alive == 0 or too_far or float(rec["age"]) > 150.0:
			_active.remove_at(i)
			event_ended.emit(rec["event"])

	# Trim live criminals.
	for i in range(_crime.size() - 1, -1, -1):
		var c = _crime[i]
		if not is_instance_valid(c) or c.get("is_dead"):
			_crime.remove_at(i)
		elif c.global_position.distance_to(p) > DESPAWN_DISTANCE:
			c.queue_free()
			_crime.remove_at(i)
	while _crime.size() > MAX_ACTIVE_CRIMINALS:
		var old = _crime.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func active_count() -> int:
	return _active.size()
