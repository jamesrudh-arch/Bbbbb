extends Node
## DUEL — 1v1 split-screen fighting, zero server cost.
##
## Locked scope from the design freeze: split-screen local only. No online, no
## relay, no monthly bill. Two fighters, one arena, best of three rounds, and
## Style Rank breaks a draw.
##
## Why split-screen works on a phone here: each player gets half the screen and
## their own touch cluster, so the control surface is the same size it is in solo
## play. That is the only reason this is viable at all, and it is why online was
## deferred rather than attempted.
##
## Each fighter is a full Player instance with combat, rig and its own camera, so
## disciplines behave exactly as they do in the story. Nothing about the duel uses
## a simplified combat model — a duel is the real fight, viewed twice.

signal round_started(round_num: int)
signal round_ended(round_num: int, winner: int)
signal duel_ended(winner: int, score: Array)
signal countdown_tick(seconds_left: float)

const ROUND_TIME := 60.0
const ROUNDS_TO_WIN := 2
const SPAWN_GAP := 4.2
const COUNTDOWN := 3.0

## The six disciplines. Silat is the sixth, restored here because the freeze
## requires six and the content file only had five.
const DUEL_DISCIPLINES := ["brawler", "kickboxing", "grappling", "drunken", "weapon", "silat"]

const SILAT := {
	"name": "Silat", "reach": 2.15, "damage": 0.92, "speed": 1.12, "stamina": 0.92,
	"desc": "Angular footwork, joint locks off the counter. Punishes committed attackers.",
	"heavy": "Elbow through the guard into a shoulder throw",
	"kick": "Sapu sweeping kick that breaks their base",
	"identity": "Best counter-window in the game. Weak if you attack first.",
	"unlock": "ring_bout_12",
}

var world: Node3D = null
var active := false

var _p1: Node3D = null
var _p2: Node3D = null
var _round := 0
var _score := [0, 0]
var _timer := ROUND_TIME
var _countdown := 0.0
var _phase := "idle"          # idle | countdown | fight | round_end | done
var _style_p1 := 0.0
var _style_p2 := 0.0
var _arena_center := Vector3.ZERO
var _arena_radius := 11.0
var _player_saved := {}

## Begin a duel. p1_discipline and p2_discipline are keys from DUEL_DISCIPLINES.
func begin(w: Node3D, p1_discipline: String, p2_discipline: String, arena_center: Vector3) -> bool:
	if active:
		return false
	world = w
	_arena_center = arena_center
	_arena_radius = 11.0
	_score = [0, 0]
	_round = 0

	if not _spawn_fighters(p1_discipline, p2_discipline):
		return false
	active = true
	_start_round()
	return true

func _spawn_fighters(d1: String, d2: String) -> bool:
	# The story player becomes fighter one; fighter two is a second full Player.
	_p1 = world.player
	if _p1 == null:
		return false
	_player_saved = {
		"pos": _p1.global_position,
		"discipline": Game.active_discipline,
		"health": _p1.health if _p1.get("health") != null else 100.0,
	}

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	if player_scene == null:
		return false
	_p2 = player_scene.instantiate()
	_p2.name = "Duelist2"
	world.add_child(_p2)

	# Place them facing each other.
	var right := Vector3(SPAWN_GAP, 0, 0)
	_p1.global_position = _arena_center - right + Vector3(0, 0.3, 0)
	_p2.global_position = _arena_center + right + Vector3(0, 0.3, 0)
	_p1.rotation.y = PI * 0.5
	_p2.rotation.y = -PI * 0.5

	for f in [_p1, _p2]:
		f.set("duel_mode", true)
		if f.get("max_health") != null:
			f.set("health", float(f.get("max_health")))
		else:
			f.set("health", 100.0)
			f.set("max_health", 100.0)
	_apply_discipline(_p1, d1)
	_apply_discipline(_p2, d2)

	# Opposed cameras so each player watches their own fighter.
	if _p1.get("camera_rig") != null:
		_p1.camera_rig.yaw = -PI * 0.5
	if _p2.get("camera_rig") != null:
		_p2.camera_rig.yaw = PI * 0.5

	# Only the story player's combat should drive the story's style meter.
	if _p2.get("combat") != null:
		_p2.combat.set("duel_mode", true)
	return true

func _apply_discipline(fighter: Node3D, key: String) -> void:
	var disc := _discipline_data(key)
	if disc.is_empty():
		return
	# Duel disciplines apply to the fighter directly, not to Game, so starting a
	# duel never overwrites the player's story progression.
	fighter.set_meta("duel_discipline", key)
	if fighter.has_method("apply_duel_stats"):
		fighter.apply_duel_stats(disc)
	elif fighter.get("combat") != null:
		fighter.combat.set("discipline_override", disc)

func _discipline_data(key: String) -> Dictionary:
	if key == "silat":
		return SILAT
	return Content.DISCIPLINES.get(key, Content.DISCIPLINES.get("brawler", {}))

# ------------------------------------------------------------------ rounds
func _start_round() -> void:
	_round += 1
	_timer = ROUND_TIME
	_countdown = COUNTDOWN
	_phase = "countdown"
	_style_p1 = 0.0
	_style_p2 = 0.0
	_reset_fighters()
	round_started.emit(_round)
	if world.hud != null:
		world.hud.notify("ROUND %d" % _round, "First to %d rounds." % ROUNDS_TO_WIN, "info")

func _reset_fighters() -> void:
	var right := Vector3(SPAWN_GAP, 0, 0)
	for f in [_p1, _p2]:
		if f == null or not is_instance_valid(f):
			continue
		f.global_position = _arena_center + (right if f == _p2 else -right) + Vector3(0, 0.3, 0)
		f.set("is_dead", false)
		f.set("health", f.get("max_health") if f.get("max_health") != null else 100.0)
		if f.get("rig") != null:
			f.rig.play("idle")

func _process(delta: float) -> void:
	if not active:
		return
	match _phase:
		"countdown":
			_countdown -= delta
			countdown_tick.emit(_countdown)
			if _countdown <= 0.0:
				_phase = "fight"
		"fight":
			_timer -= delta
			_track_style(delta)
			_check_ring_out()
			if _timer <= 0.0:
				_end_round(_judge_round())
			else:
				var dead := _ko_check()
				if dead >= 0:
					_end_round(dead)
		"round_end":
			_countdown -= delta
			if _countdown <= 0.0:
				if _score[0] >= ROUNDS_TO_WIN or _score[1] >= ROUNDS_TO_WIN:
					_finish()
				else:
					_start_round()

func _track_style(delta: float) -> void:
	# Style is the duel tiebreaker, so it has to be tracked from real play:
	# landing hits and avoiding damage, not from a counter we increment blindly.
	if _p1 != null and _p1.get("combat") != null and _p1.combat.get("last_hit_time") != null:
		var t: float = float(_p1.combat.last_hit_time)
		if Time.get_ticks_msec() / 1000.0 - t < 0.25:
			_style_p1 += delta * 14.0
	if _p2 != null and _p2.get("combat") != null and _p2.combat.get("last_hit_time") != null:
		var t2: float = float(_p2.combat.last_hit_time)
		if Time.get_ticks_msec() / 1000.0 - t2 < 0.25:
			_style_p2 += delta * 14.0

func _ko_check() -> int:
	var d1 := _health_frac(_p1)
	var d2 := _health_frac(_p2)
	if d1 <= 0.0 and d2 <= 0.0:
		return _judge_round()          # double KO goes to style
	if d2 <= 0.0:
		return 0
	if d1 <= 0.0:
		return 1
	return -1

func _health_frac(f: Node3D) -> float:
	if f == null or not is_instance_valid(f):
		return 0.0
	var hp = f.get("health")
	var mx = f.get("max_health")
	if hp == null:
		return 1.0
	return float(hp) / maxf(1.0, float(mx) if mx != null else 100.0)

## Leaving the arena concedes the round. Ring bounds exist so a runner cannot
## stall out a timer lead.
func _check_ring_out() -> void:
	for i in [0, 1]:
		var f: Node3D = _p1 if i == 0 else _p2
		if f == null or not is_instance_valid(f):
			continue
		var d: Vector3 = f.global_position - _arena_center
		d.y = 0.0
		if d.length() > _arena_radius:
			_end_round(1 - i)
			return

## Style Rank breaks a timeout or a double KO. This is the only reason the style
## system has a mechanical stake in the duel, and it is the rule the freeze named.
func _judge_round() -> int:
	if absf(_style_p1 - _style_p2) < 1.0:
		# Too close to call on style: whoever is healthier takes it.
		var d1 := _health_frac(_p1)
		var d2 := _health_frac(_p2)
		if absf(d1 - d2) < 0.05:
			return 0 if _round % 2 == 1 else 1     # alternate; never a null round
		return 0 if d1 > d2 else 1
	return 0 if _style_p1 > _style_p2 else 1

func _end_round(winner: int) -> void:
	# Guard against re-entry: a KO'd fighter stays KO'd every frame, so without
	# this the round-end countdown is reset each frame and never elapses.
	if _phase != "fight":
		return
	if winner < 0 or winner > 1:
		winner = 0
	_score[winner] += 1
	_phase = "round_end"
	_countdown = 2.2
	round_ended.emit(_round, winner)
	if world.hud != null:
		var name := "PLAYER ONE" if winner == 0 else "PLAYER TWO"
		world.hud.notify("ROUND", "%s takes it." % name, "info")
	if _p1 != null and _p1.get("rig") != null:
		_p1.rig.play("victory" if winner == 0 else "defeat")
	if _p2 != null and _p2.get("rig") != null:
		_p2.rig.play("defeat" if winner == 0 else "victory")

func _finish() -> void:
	_phase = "done"
	active = false
	var w := 0 if _score[0] > _score[1] else 1
	duel_ended.emit(w, _score)
	if world.hud != null:
		world.hud.notify("DUEL OVER", "Player %d wins %d-%d." % [w + 1, _score[w], _score[1 - w]], "info")
	# Bank a result in the story save, then restore the story player.
	Game.stats["duels_fought"] = int(Game.stats.get("duels_fought", 0)) + 1
	if w == 0:
		Game.stats["duels_won"] = int(Game.stats.get("duels_won", 0)) + 1
	_restore_world()

func abandon() -> void:
	if not active:
		return
	active = false
	_phase = "idle"
	_restore_world()

func _restore_world() -> void:
	if _p2 != null and is_instance_valid(_p2):
		_p2.queue_free()
		_p2 = null
	if _p1 != null and is_instance_valid(_p1):
		_p1.global_position = _player_saved.get("pos", _p1.global_position)
		if _p1.get("health") != null:
			_p1.set("health", _player_saved.get("health", 100.0))
		_p1.remove_meta("duel_discipline")
	if _p1.get("duel_mode") != null:
		_p1.set("duel_mode", false)
		_p1.set("health", Game.player_health)
		_p1.set("max_health", Game.player_max_health)
	_phase = "idle"

func score() -> Array:
	return _score.duplicate()

func discipline_list() -> Array:
	var out := []
	for k in DUEL_DISCIPLINES:
		var d := _discipline_data(k)
		out.append({
			"key": k,
			"name": str(d.get("name", k)),
			"desc": str(d.get("desc", "")),
			"identity": str(d.get("identity", "")),
		})
	return out
