extends Node
## Drives a real duel and reports what actually happened: did the second fighter
## spawn, did the split view build, did rounds advance, did it finish cleanly.
func _ready() -> void:
	_go.call_deferred()

func _go() -> void:
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.8).timeout
	print("[U] duel=", world.duel != null, " split=", world.split_view != null)
	print("[U] disciplines=", world.duel.discipline_list().size())

	var ok: bool = world.start_duel("brawler", "silat")
	print("[U] start_duel ->", ok)
	await get_tree().create_timer(0.4).timeout
	print("[U] p1=", world.duel._p1 != null, " p2=", world.duel._p2 != null)
	print("[U] split active=", world.split_view.active)
	print("[U] phase=", world.duel._phase, " round=", world.duel._round)

	# Let the countdown run, then check the fight state advances.
	await get_tree().create_timer(3.6).timeout
	print("[U] after countdown: phase=", world.duel._phase, " timer=%.1f" % world.duel._timer)

	# Force a KO to prove round scoring works.
	if world.duel._p2 != null:
		world.duel._p2.set("health", 0.0)
	await get_tree().create_timer(0.4).timeout
	print("[U] after p2 KO: score=", world.duel.score(), " phase=", world.duel._phase)

	# Let round two start.
	await get_tree().create_timer(2.6).timeout
	print("[U] round now=", world.duel._round, " phase=", world.duel._phase)

	# Force a second KO to finish the duel 2-0.
	if world.duel._p2 != null and is_instance_valid(world.duel._p2):
		world.duel._p2.set("health", 0.0)
	for i in 16:
		await get_tree().create_timer(0.5).timeout
		print("[U] t=%.1f phase=%s round=%d score=%s cd=%.2f" % [
			float(i) * 0.5, world.duel._phase, world.duel._round,
			str(world.duel.score()), world.duel._countdown])
		if not world.duel.active:
			break
	print("[U] duel active=", world.duel.active, " score=", world.duel.score())
	print("[U] split disengaged=", not world.split_view.active)
	print("[U] p2 cleaned up=", world.duel._p2 == null)
	print("[U] stats duels_fought=", Game.stats.get("duels_fought", 0))
	get_tree().quit()
