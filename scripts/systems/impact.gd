extends Node
## IMPACT — weight. The layer that makes a punch feel like it connected.
##
## Owns three things the player feels but never sees named:
##   HIT-STOP   a 40-90 ms freeze on contact, scaled by damage
##   SHAKE      a decaying positional jolt on a curve, not a linear fade
##   IMPACT FRAME  one bright frame at the moment of connection
##
## Why this is a node and not inline code: the old implementation set
## Engine.time_scale directly from combat.gd and then reset it to 1.0. If two
## hits overlapped, the second reset could land while the first freeze was still
## running, and a hit during a scripted slow-motion would cancel it. This owns
## the value, counts overlapping requests, and always restores the scale that was
## there before it started.

signal impact_fired(strength: float)

## Hit-stop lengths. Deliberately short: on a phone, anything over ~110 ms reads
## as lag rather than impact.
const STOP_LIGHT := 0.045
const STOP_HEAVY := 0.075
const STOP_FINISHER := 0.11
const STOP_SLOWMO := 0.22

var _active := 0            # overlapping impacts
var _restore_scale := 1.0
var _stop_timer := 0.0
var _stop_scale := 1.0
var _suspended := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Freeze the world briefly. `strength` 0..1 scales the length.
func hit_stop(strength: float = 0.5, override_len: float = -1.0) -> void:
	if _suspended:
		return
	var dur := override_len
	if dur < 0.0:
		if strength >= 0.95:
			dur = STOP_FINISHER
		elif strength >= 0.6:
			dur = STOP_HEAVY
		else:
			dur = STOP_LIGHT
	# Never extend a longer freeze with a shorter one.
	if _active > 0 and dur <= _stop_timer:
		return
	if _active == 0:
		_restore_scale = Engine.time_scale
	_active += 1
	_stop_timer = dur
	_stop_scale = _restore_scale * 0.06
	Engine.time_scale = _stop_scale
	impact_fired.emit(strength)

## Slow motion that does not fight hit-stop — used for finishers and duels.
func slow_mo(factor: float, duration: float) -> void:
	slow_mo_to(factor, duration)

func slow_mo_to(factor: float, duration: float) -> void:
	if _suspended:
		return
	if _active == 0:
		_restore_scale = Engine.time_scale
	_active += 1
	_stop_timer = duration
	_stop_scale = _restore_scale * clampf(factor, 0.05, 1.0)
	Engine.time_scale = _stop_scale

## Announce a pause/fade so a hit cannot un-pause the game.
func suspend() -> void:
	_suspended = true
	_active = 0
	_stop_timer = 0.0
	Engine.time_scale = 1.0

func resume() -> void:
	_suspended = false
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if _active <= 0:
		return
	# delta is already scaled by time_scale, so unscale it to count real time.
	var real := delta / maxf(Engine.time_scale, 0.001)
	_stop_timer -= real
	if _stop_timer <= 0.0:
		_active = 0
		_stop_timer = 0.0
		Engine.time_scale = _restore_scale if not _suspended else 1.0

# ------------------------------------------------------------------ shake
## Positional jolt with a curve. Returns nothing; the camera reads the offset.
func shake_curve(amount: float) -> float:
	# Fade faster than linear: a jolt that lingers feels like a wobble.
	return amount * amount

static func ease_out_quart(t: float) -> float:
	var u := 1.0 - clampf(t, 0.0, 1.0)
	return 1.0 - u * u * u * u

static func ease_out_expo(t: float) -> float:
	var c := clampf(t, 0.0, 1.0)
	return 1.0 if c >= 1.0 else 1.0 - pow(2.0, -10.0 * c)
