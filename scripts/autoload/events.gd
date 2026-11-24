extends Node
## EVENTS — the living-city event bus.
## Systems report what happened; the event director decides what the city does
## about it (spawn reaction, raise noise, shift NPC mood, log a radio report).

signal recorded(kind: String, data: Dictionary)

var log: Array = []
var last: Dictionary = {}
var _recent: Dictionary = {}

const COOLDOWN := {
	"district_enter": 6.0, "combat_hit": 0.4, "npc_talk": 1.0,
	"vehicle_enter": 2.0, "shop_purchase": 0.5, "mission_step": 1.0,
}

func record(kind: String, data: Variant = null) -> void:
	var payload: Dictionary = data if data is Dictionary else {}
	var now := Time.get_ticks_msec() / 1000.0
	if _recent.has(kind) and now - float(_recent[kind]) < float(COOLDOWN.get(kind, 0.0)):
		return
	_recent[kind] = now
	last = {"kind": kind, "data": payload, "at": now}
	log.append(last)
	if log.size() > 200: log.pop_front()
	recorded.emit(kind, payload)

func recent(kind: String, within: float = 5.0) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return _recent.has(kind) and now - float(_recent[kind]) <= within

func count(kind: String) -> int:
	var n := 0
	for e in log:
		if e["kind"] == kind: n += 1
	return n
