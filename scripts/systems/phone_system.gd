extends Node
## PHONE SYSTEM — scheduling and state for calls and messages.
##
## Calls are driven by story state, not random timers: a call fires when its
## trigger condition becomes true AND the player is not in combat and not inside a
## cutscene, so the phone never interrupts critical action. Each call has a
## cooldown and (for `once` calls) a fired flag, so nothing repeats incorrectly.

const MIN_GAP := 45.0          # seconds between calls
const QUIET_AFTER_COMBAT := 6.0

var world: Node3D = null
var _cooldown := 20.0
var _combat_clear := 0.0
var _fired: Dictionary = {}
var _msg_delivered: Dictionary = {}

## Trigger table: call id -> condition on Game state.
## `world` is assigned before any of these run.
func _triggers() -> Array:
	return [
		{"id": "ngozi_checkin", "when": func(): return Game.hour >= 8.0 and Game.hour < 21.0},
		{"id": "kola_threat", "when": func(): return Game.has_flag("homecoming_done")},
		{"id": "tunde_garage", "when": func(): return Game.has_flag("short_count_done")},
		{"id": "ada_invite", "when": func(): return Game.has_flag("short_count_done") and Game.hour >= 12.0},
		{"id": "chidi_warning", "when": func(): return Game.has_flag("iron_debt_done")},
		{"id": "warning_from_mara", "when": func(): return Game.wanted >= 2},
		{"id": "police_warning", "when": func(): return Game.wanted >= 3},
	]

func setup(w: Node3D) -> void:
	world = w

func _process(delta: float) -> void:
	if world == null:
		return
	var player = world.player
	if player == null:
		return
	# Never ring during combat or while a cinematic/dialogue owns the screen.
	if player.combat != null and player.combat.in_combat:
		_combat_clear = 0.0
		return
	_combat_clear += delta
	if _combat_clear < QUIET_AFTER_COMBAT:
		return
	if world.hud != null and world.hud._phone != null and world.hud._phone.visible:
		return
	_cooldown -= delta
	_deliver_messages()
	if _cooldown > 0.0:
		return
	for t in _triggers():
		var id: String = t["id"]
		var spec: Dictionary = Content.CALLS.get(id, {})
		if spec.is_empty():
			continue
		if _fired.get(id, false):
			continue
		if spec.get("once", false) and Game.has_flag(str(spec.get("flag", "fired_" + id))):
			continue
		var ok: bool = (true == t["when"].call())
		if not ok:
			continue
		_fired[id] = true
		_cooldown = MIN_GAP
		world.hud.ring_phone(id)
		return

## Message threads land as the in-game clock passes their scheduled hour.
func _deliver_messages() -> void:
	for cid in Content.MESSAGES:
		var list: Array = Content.MESSAGES[cid]
		for i in list.size():
			var key := "%s:%d" % [cid, i]
			if _msg_delivered.get(key, false):
				continue
			var m: Dictionary = list[i]
			var at := float(m.get("at", 0.0))
			# Deliver once the clock has passed the hour (same day or later).
			if Game.hour + 0.001 < at:
				continue
			_msg_delivered[key] = true
			Game.push_message(cid, str(m.get("text", "")))
