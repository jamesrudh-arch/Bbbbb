extends Node
## RESCUE — the "unstick" safety net.
##
## Every open-world game ships with the bug where the player gets wedged in
## geometry, trapped by an NPC, or soft-locked in a mission. This watches for it
## and offers a way out that never requires the player to lose progress.

signal offer_rescue(reason: String)

const STUCK_TIME := 6.0        # seconds without meaningful movement while input
const FALL_LIMIT := -40.0      # below the world floor
const CHECK_INTERVAL := 0.5

var world: Node3D = null
var _stuck := 0.0
var _tick := 0.0
var _last_pos := Vector3.INF
var _offered := false

func setup(w: Node3D) -> void:
	world = w

func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	# A conversation, cutscene or menu legitimately parks the player. Being still
	# is not being stuck.
	if world.dialogue_active():
		_stuck = 0.0
		return
	if world.get("player") != null and (true == world.player.get("dialogue_locked")):
		_stuck = 0.0
		return
	_tick = CHECK_INTERVAL
	var p = world.player
	var pos: Vector3 = p.global_position

	# Fell out of the world.
	if pos.y < FALL_LIMIT:
		_offer("You fell out of the world.")
		return

	# Wedged: the player is pushing but not moving.
	var pressing: bool = Vector2(p.velocity.x, p.velocity.z).length() > 0.35
	if _last_pos != Vector3.INF and pos.distance_to(_last_pos) < 0.06 and pressing:
		_stuck += CHECK_INTERVAL
		if _stuck >= STUCK_TIME:
			_offer("You appear to be stuck.")
			_stuck = 0.0
	else:
		_stuck = maxf(0.0, _stuck - CHECK_INTERVAL * 0.5)
	_last_pos = pos

func _offer(reason: String) -> void:
	if _offered:
		return
	_offered = true
	Crash.event("rescue_offer", reason)
	offer_rescue.emit(reason)

## Put the player on the nearest street and clear the wedged state.
func unstick() -> void:
	if world == null or world.player == null:
		return
	var p = world.player
	var block := 40.0
	if world.builder != null and "BLOCK" in world.builder:
		block = float(world.builder.BLOCK)
	var pos: Vector3 = p.global_position
	var snapped := Vector3(round(pos.x / block) * block, pos.y + 2.0, round(pos.z / block) * block)
	p.global_position = snapped
	if p is CharacterBody3D:
		(p as CharacterBody3D).velocity = Vector3.ZERO
	_offered = false
	_stuck = 0.0
	Crash.event("rescue_unstick", str(snapped))

## Last-resort: return to the nearest safehouse and keep everything else.
func to_safehouse() -> void:
	if world == null:
		return
	var target: Vector3 = world.builder.district_center(Game.current_district) if world.builder != null else Vector3.ZERO
	world.player.global_position = target + Vector3(0, 2.0, 0)
	_offered = false
	_stuck = 0.0
	Crash.event("rescue_safehouse", Game.current_district)
