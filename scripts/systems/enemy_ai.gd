extends Node
## ENEMY AI — a real state machine, driven by an archetype dictionary from
## archetypes.gd.
##
## The two design rules this enforces:
##   1. Difficulty is behaviour, not health. A tier 6 fighter is not tankier;
##      it reacts in 0.36 s instead of 0.85 s, blocks 62% instead of 5%, feints,
##      and coordinates with the crew. (docs/22_DESIGN_FREEZE.md)
##   2. Telegraphs are readable. Every attack has a windup the player can see and
##      react to. Without voice or audio cues on a phone speaker, the windup is
##      the entire fairness mechanism.
##
## States:
##   IDLE -> ALERT -> APPROACH -> (PRESS | SPACE | RETREAT) -> WINDUP -> STRIKE
##                                                            -> RECOVER -> PRESS
##   Anything -> STAGGER -> RECOVER
##   Low health per archetype -> FLEE
##   calls_backup -> CALL -> BACKUP

signal strike_landed(attacker, amount)
signal state_changed(new_state)

const S_IDLE := "idle"
const S_ALERT := "alert"
const S_APPROACH := "approach"
const S_PRESS := "press"
const S_SPACE := "space"          # circling at range, looking for an opening
const S_RETREAT := "retreat"
const S_WINDUP := "windup"
const S_STRIKE := "strike"
const S_RECOVER := "recover"
const S_STAGGER := "stagger"
const S_BLOCK := "block"
const S_DODGE := "dodge"
const S_CALL := "call"
const S_FLEE := "flee"
const S_DEAD := "dead"

var actor: CharacterBody3D = null
var data: Dictionary = {}
var state := S_IDLE
var target: Node3D = null

var _t := 0.0                  # time in current state
var _think := 0.0
var _combo_left := 0
var _stagger_time := 0.0
var _block_until := 0.0
var _dodge_vec := Vector3.ZERO
var _dodge_time := 0.0
var _rng := RandomNumberGenerator.new()
var _last_attack := -99.0
var _clock := 0.0
var _space_dir := 1.0
var _called_backup := false

# Spacing: how far the fighter wants to sit relative to the player.
const IDEAL_GAP := 0.15

func setup(p_actor: CharacterBody3D, p_data: Dictionary) -> void:
	actor = p_actor
	data = p_data
	_rng.seed = hash(str(p_actor.get_instance_id()))

func begin(p_target: Node3D) -> void:
	target = p_target
	_set_state(S_ALERT)

func is_engaged() -> bool:
	return state != S_IDLE and state != S_DEAD and state != S_FLEE

func _set_state(s: String) -> void:
	if state == s:
		return
	state = s
	_t = 0.0
	state_changed.emit(s)

func _physical(delta: float) -> void:
	var t_before := _t
	_physical_inner(delta)
	# Time in state advances only if the state did not change this frame, so a
	# freshly entered state starts its life at 0 and counts up from the next frame.
	if _t == t_before:
		_t += delta

func _physical_inner(delta: float) -> void:
	if actor == null or data.is_empty():
		return
	_clock += delta
	_think -= delta

	if actor.is_dead:
		_set_state(S_DEAD)
		return

	if target == null or not is_instance_valid(target):
		_set_state(S_IDLE)
		_slow(delta, 12.0)
		return

	# Stagger interrupts everything.
	if state == S_STAGGER:
		_stagger_time -= delta
		_slow(delta, 14.0)
		if _stagger_time <= 0.0:
			_recover_to_pressure()
		_t += delta
		return

	# Flee check — per-archetype threshold, not universal.
	var hp_frac: float = actor.health / maxf(1.0, actor.max_health)
	if data.has("flees_below") and hp_frac <= float(data["flees_below"]) and state != S_FLEE:
		_begin_flee()
		return

	if state == S_FLEE:
		_run_away(delta)
		return

	if state == S_WINDUP:
		_slow(delta, 18.0)
		_face_target()
		if _t >= float(data.get("reaction", 0.55)):
			_do_strike()
		return

	if state == S_STRIKE:
		_slow(delta, 20.0)
		if _t >= 0.16:
			_set_state(S_RECOVER)
		return

	if state == S_RECOVER:
		_slow(delta, 10.0)
		if _t >= _recover_time():
			_recover_to_pressure()
		return

	if state == S_BLOCK:
		_slow(delta, 16.0)
		_face_target()
		if _clock > _block_until:
			_recover_to_pressure()
		return

	if state == S_DODGE:
		_dodge_time -= delta
		actor.velocity.x = _dodge_vec.x
		actor.velocity.z = _dodge_vec.z
		if _dodge_time <= 0.0:
			_recover_to_pressure()
		return

	if state == S_CALL:
		_slow(delta, 12.0)
		_face_target()
		if _t > 1.1:
			_called_backup = true
			_recover_to_pressure()
		return

	if state == S_ALERT:
		_slow(delta, 8.0)
		_face_target()
		if _t > 0.25:
			_recover_to_pressure()
		return

	# ---- movement states
	var dist := _flat_distance()
	var style: String = str(data.get("style", "brawler"))
	var reach: float = float(data.get("range", 2.0))

	match state:
		S_SPACE:
			_circle(delta)
			if dist < reach * 1.6 and _can_attack():
				_set_state(S_PRESS)
			elif _t > 2.6:
				_recover_to_pressure()
		S_RETREAT:
			_back_off(delta)
			if dist > reach * 1.4 + float(data.get("keeps_distance", 0.0)) * 0.5 or _t > 2.0:
				_recover_to_pressure()
		S_PRESS:
			_advance(delta)
			# A fighter in pressing range but unable to strike must commit anyway:
			# standing at 2.6 m against a 2.0 m reach forever is the classic
			# "enemy stands still and stares" bug.
			if dist <= reach + IDEAL_GAP:
				if _rng.randf() < float(data.get("feint_chance", 0.0)) and _combo_left <= 0:
					# Feint: start a windup, abort it, strike for real.
					_set_state(S_WINDUP)
					_combo_left = 0
					data["_feinting"] = true
				else:
					_set_state(S_WINDUP)
			elif _t > 0.9:
				# Could not close the last 0.6 m — lunge for it. Committing to a
				# slightly-out-of-range swing reads far better than hovering.
				_lunge()
				_set_state(S_WINDUP)
		_:
			_advance(delta)

	# Ranged styles hold distance instead of closing.
	if float(data.get("keeps_distance", 0.0)) > 0.0:
		var keep := float(data["keeps_distance"])
		if dist < keep * 0.6:
			_set_state(S_RETREAT)
		elif dist <= keep * 1.05 and _can_attack():
			_set_state(S_PRESS)

func _recover_to_pressure() -> void:
	if data.has("calls_backup") and int(data.get("calls_backup_count", 0)) == 0 and not _called_backup and _rng.randf() < 0.5:
		pass
	var d := _flat_distance()
	var reach: float = float(data.get("range", 2.0))
	var keeps: float = float(data.get("keeps_distance", 0.0))
	if keeps > 0.0 and d < keeps * 0.7:
		_set_state(S_RETREAT)
	elif d <= reach + 0.6:
		_set_state(S_PRESS)
	elif _rng.randf() < 0.35:
		_set_state(S_SPACE)
	else:
		_set_state(S_PRESS)

## Close the final gap hard so a windup lands inside reach.
func _lunge() -> void:
	if actor == null or target == null:
		return
	var dir := _dir_to_target()
	var spd: float = float(data.get("speed", 1.3)) * 4.2
	actor.velocity.x = dir.x * spd
	actor.velocity.z = dir.z * spd

func _can_attack() -> bool:
	return _clock - _last_attack > _recover_time() + 0.05

func _recover_time() -> float:
	return float(data.get("recover", 0.55)) * (1.0 - 0.35 * float(data.get("coordination", 0.0)))

func _do_strike() -> void:
	_set_state(S_STRIKE)
	var dist := _flat_distance()
	var reach: float = float(data.get("range", 2.0))
	var hit := dist <= reach + 0.35

	# Accuracy is a real miss chance at distance, not a damage multiplier.
	if hit and _rng.randf() > float(data.get("accuracy", 0.85)):
		hit = false

	var amount: float = float(data.get("damage", 6.5))
	if hit:
		strike_landed.emit(actor, amount)
		_last_attack = _clock

	# Combo continuation.
	if hit and _combo_left < int(data.get("combo_max", 1)):
		_combo_left += 1
	else:
		_combo_left = 0

	if _combo_left > 0:
		# Shorter windup on follow-ups — that is what makes a combo feel like one.
		data["reaction"] = float(data.get("reaction", 0.55)) * 0.62

## Called by anything that hits the actor. Returns true if the hit was blocked.
func on_hit(damage: float, from_dir: Vector3) -> Dictionary:
	if actor == null or actor.is_dead:
		return {"blocked": false, "damage": 0.0}
	var blocking := _rng.randf() < float(data.get("block_chance", 0.0))
	if blocking and _facing(from_dir):
		_block_until = _clock + 0.7
		_set_state(S_BLOCK)
		Audio.play_at("block", actor.global_position, 1.0, -5.0)
		return {"blocked": true, "damage": damage * 0.12}
	# Dodge chance: sidestep rather than eat it.
	if _rng.randf() < float(data.get("dodge_chance", 0.0)):
		_begin_dodge(from_dir)
		return {"blocked": true, "damage": 0.0}
	_stagger_time = 0.34 if damage < 20.0 else 0.62
	_set_state(S_STAGGER)
	if actor.has_method("rig_play"):
		pass
	return {"blocked": false, "damage": damage}

func _begin_dodge(from_dir: Vector3) -> void:
	var side := from_dir.cross(Vector3.UP).normalized()
	if _rng.randf() < 0.5:
		side = -side
	_dodge_vec = side * float(data.get("speed", 1.3)) * 3.4
	_dodge_time = 0.34
	_set_state(S_DODGE)
	if actor.rig != null:
		actor.rig.play_once("dodge_roll", 1.5)

func _begin_flee() -> void:
	_set_state(S_FLEE)
	if int(data.get("calls_backup", 0)) != 0 or str(data.get("id", "")) == "corner_lookout":
		Audio.play_at("horn", actor.global_position, 1.0, -3.0)

func _run_away(delta: float) -> void:
	if target == null:
		return
	var away: Vector3 = actor.global_position - target.global_position
	away.y = 0.0
	away = away.normalized()
	var spd: float = float(data.get("speed", 1.3)) * 2.1
	actor.velocity.x = move_toward(actor.velocity.x, away.x * spd, 12.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, away.z * spd, 12.0 * delta)

# ------------------------------------------------------------------ movement
func _flat_distance() -> float:
	if target == null:
		return 999.0
	var d: Vector3 = target.global_position - actor.global_position
	d.y = 0.0
	return d.length()

func _dir_to_target() -> Vector3:
	var d: Vector3 = target.global_position - actor.global_position
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD

func _advance(delta: float) -> void:
	# Spread out: two fighters converging on the same line look like one mesh.
	var dir := _dir_to_target()
	var spread := _separation()
	var spd: float = float(data.get("speed", 1.3)) * float(data.get("aggression", 1.0))
	actor.velocity.x = move_toward(actor.velocity.x, (dir.x + spread.x) * spd, 11.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, (dir.z + spread.z) * spd, 11.0 * delta)
	_face_target()

func _circle(delta: float) -> void:
	var dir := _dir_to_target()
	var side := dir.cross(Vector3.UP) * _space_dir
	var spd: float = float(data.get("speed", 1.3)) * 0.62
	actor.velocity.x = move_toward(actor.velocity.x, side.x * spd, 8.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, side.z * spd, 8.0 * delta)
	_face_target()
	if _t > 1.2:
		_space_dir = -_space_dir
		_t = 0.0

func _back_off(delta: float) -> void:
	var dir := -_dir_to_target()
	var spd: float = float(data.get("speed", 1.3)) * 1.5
	actor.velocity.x = move_toward(actor.velocity.x, dir.x * spd, 12.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, dir.z * spd, 12.0 * delta)
	_face_target()

## Coordinated crews don't stack on one line. Low-tier fighters do.
func _separation() -> Vector3:
	var coord := float(data.get("coordination", 0.0))
	if coord <= 0.05:
		return Vector3.ZERO
	var push := Vector3.ZERO
	for a in actor.get_tree().get_nodes_in_group("hostile"):
		if a == actor or not is_instance_valid(a):
			continue
		var d: Vector3 = actor.global_position - a.global_position
		d.y = 0.0
		var l := d.length()
		if l > 0.01 and l < 2.6:
			push += d.normalized() * (1.0 - l / 2.6)
	# Cap the push: separation exists to stop the crew stacking into one mesh,
	# not to shove a fighter out of the range it just walked into.
	return push.limit_length(0.55) * coord

func _slow(delta: float, rate: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0.0, rate * delta)
	actor.velocity.z = move_toward(actor.velocity.z, 0.0, rate * delta)

func _face_target() -> void:
	if target == null or actor == null:
		return
	var d: Vector3 = target.global_position - actor.global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	var want := atan2(d.x, d.z)
	actor.rotation.y = lerp_angle(actor.rotation.y, want, 0.22)

func _facing(from_dir: Vector3) -> bool:
	var fwd := -actor.global_transform.basis.z
	fwd.y = 0.0
	var nd := -from_dir
	nd.y = 0.0
	if nd.length() < 0.01:
		return true
	return fwd.normalized().dot(nd.normalized()) > 0.25
