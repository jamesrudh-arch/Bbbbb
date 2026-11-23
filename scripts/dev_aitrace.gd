extends Node
## Traces enemy_ai transitions directly. Run as a scene so autoloads exist.
var archetype_id := "street_thug"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--arch="):
			archetype_id = a.trim_prefix("--arch=")
	var ai = load("res://scripts/systems/enemy_ai.gd").new()
	add_child(ai)
	# Must be a real actor: enemy_ai reads actor.is_dead, actor.health and
	# actor.velocity. A bare CharacterBody3D silently aborts the state machine.
	var a = load("res://scripts/npc/actor.gd").new()
	a.setup({"role": "thug", "faction": "railhead", "hostile": true, "health": 60.0})
	add_child(a)
	a.global_position = Vector3.ZERO
	var t := Node3D.new()
	add_child(t)
	t.global_position = Vector3(2.6, 0, 0)
	ai.setup(a, Archetypes.make(archetype_id, 4))
	ai.begin(t)
	var last := ""
	var counts := {}
	for i in 420:
		ai._physical(1.0/60.0)
		if i < 8 or i % 100 == 0:
			print("[T]   i=%d state=%s _t=%.3f dist=%.2f" % [i, ai.state, ai._t, ai._flat_distance()])
		counts[ai.state] = int(counts.get(ai.state, 0)) + 1
		if ai.state != last:
			if i < 200:
				print("[T] %3d  %s" % [i, ai.state])
			last = ai.state
	print("[T] ===== frames per state =====")
	for k in counts:
		print("[T]  %-10s %d" % [k, counts[k]])
	get_tree().quit()
