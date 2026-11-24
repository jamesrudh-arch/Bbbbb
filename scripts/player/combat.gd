extends Node
## COMBAT — the five-discipline fighting system.
## Button contract:  X = punch | Y = heavy | A = kick | B = dodge
## Each discipline changes reach, damage, speed, stamina and the specials those
## buttons produce. Guns layer on top of the same state machine.
##
## Damage flow:  attack roll -> range check -> target roll (armour) -> apply ->
##               reaction clip -> hitstop -> camera shake -> noise -> heat.

signal fight_started(target)
signal fight_ended(won: bool)
signal hit_landed(damage: float, target)

const ATTACKS := {
	"punch": {"damage": 1.0, "reach_mult": 1.0, "stamina": 6.0, "clip": "punch", "cooldown": 0.32},
	"heavy": {"damage": 2.1, "reach_mult": 1.15, "stamina": 16.0, "clip": "punch", "cooldown": 0.72},
	"kick": {"damage": 1.45, "reach_mult": 1.35, "stamina": 10.0, "clip": "punch", "cooldown": 0.48},
}

var player: CharacterBody3D
var in_combat := false
var target: Node3D = null
var targets: Array = []
var can_act := true

var _cooldown := 0.0
var _combo := 0
var _combo_window := 0.0
var _dodge_time := 0.0
var _counter_window := 0.0
var _blocking := false
var _lock_requested := false
var _gun_cooldown := 0.0

func setup(p: CharacterBody3D) -> void:
	player = p

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	_dodge_time = maxf(0.0, _dodge_time - delta)
	_counter_window = maxf(0.0, _counter_window - delta)
	_gun_cooldown = maxf(0.0, _gun_cooldown - delta)
	if _combo_window <= 0.0: _combo = 0
	if player == null: return
	if player.is_dead: return
	_scan_targets()
	_read_input()

func _scan_targets() -> void:
	# Combat is live when a hostile actor is within engagement range.
	targets.clear()
	var best: Node3D = null
	var bestd := 12.0
	for n in get_tree().get_nodes_in_group("hostile"):
		if not is_instance_valid(n): continue
		if n.get("is_dead") == true: continue
		var d: float = player.global_position.distance_to(n.global_position)
		if d < 12.0:
			targets.append(n)
			if d < bestd:
				bestd = d
				best = n
	var was := in_combat
	in_combat = not targets.is_empty() and not player.vehicle != null
	if in_combat and not was:
		target = best
		fight_started.emit(best)
		Audio.set_music_state("tension")
	elif not in_combat and was:
		target = null
		fight_ended.emit(true)
		Audio.set_music_state("chase" if Game.wanted > 0 else "explore")
	if in_combat:
		# Keep the nearest target; retarget if it dies.
		if target == null or not is_instance_valid(target) or target.get("is_dead") == true:
			target = best
		elif best != null and best != target:
			var dt: float = player.global_position.distance_to(target.global_position)
			if bestd < dt * 0.7: target = best

func _read_input() -> void:
	# B is dodge in combat only — outside combat the same button is "interact",
	# handled by interaction.gd. No conflict because this node returns early.
	if not in_combat: 
		_blocking = false
		return
	if _dodge_time > 0.0: return
	if Input.is_action_just_pressed("punch"): _attack("punch")
	elif Input.is_action_just_pressed("heavy"): _attack("heavy")
	elif Input.is_action_just_pressed("kick"): _attack("kick")
	elif Input.is_action_just_pressed("dodge"): _dodge()
	_blocking = Input.is_action_pressed("block")
	if Input.is_action_just_pressed("shoot"): _shoot()
	if Input.is_action_just_pressed("reload"): _reload()
	if Input.is_action_just_pressed("weapon_switch"): _cycle_weapon()

# ---------------------------------------------------------------- attacks
func _attack(kind: String) -> void:
	if _cooldown > 0.0 or not can_act: return
	var cfg: Dictionary = ATTACKS[kind]
	var stats: Dictionary = Game.discipline_stats()
	var stamina_cost := float(cfg["stamina"]) * float(stats["stamina"]) * 0.62
	if Game.stamina < stamina_cost * 0.6:
		Game.notify("Gassed", "Out of stamina", "error")
		return
	Game.stamina = maxf(0.0, Game.stamina - stamina_cost)
	_cooldown = float(cfg["cooldown"]) / maxf(0.6, float(stats["speed"]))
	_combo = mini(_combo + 1, 5)
	_combo_window = 0.9

	if player.rig != null:
		var clip: String = "punch"
		if kind == "kick": clip = "slash" if Game.active_discipline == "weapon" else "punch"
		if kind == "heavy": clip = "slash" if Game.active_discipline == "weapon" else "punch"
		player.rig.play(clip, float(stats["speed"]) * (1.0 + _combo * 0.03))
	Audio.play_at("punch_swing", player.global_position + Vector3(0, 1.2, 0), randf_range(0.95, 1.06), -8.0)

	# Reach is discipline-driven, so Kickboxing genuinely hits from further out.
	var reach := float(stats["reach"]) * float(cfg["reach_mult"])
	var damage := float(cfg["damage"]) * float(stats["damage"]) * (1.0 + _combo * 0.08)
	damage *= 9.0   # base scale: fists land ~9 damage

	await get_tree().create_timer(0.10).timeout
	var landed := false
	for t in targets.duplicate():
		if not is_instance_valid(t): continue
		var dxz: float = player.global_position.distance_to(t.global_position)
		if dxz <= reach:
			_apply_hit(t, damage, kind)
			landed = true
			break
	if not landed:
		# whiff: small stamina/heat penalty keeps spam honest
		Game.stamina = maxf(0.0, Game.stamina - 2.0)

func _apply_hit(t: Node3D, damage: float, kind: String) -> void:
	var armour := float(t.get("armor") if t.get("armor") != null else 0.0)
	damage *= (1.0 - clampf(armour, 0.0, 0.85))
	# Grappling ignores armour on the floor; Drunken ignores armour on counters.
	if Game.active_discipline == "grappling" or (_counter_window > 0.0 and Game.active_discipline == "drunken"):
		damage = float(ATTACKS[kind]["damage"]) * 9.0 * (1.0 + _combo * 0.08)
	if t.has_method("take_hit"):
		t.take_hit(damage, player)
	else:
		var hp = t.get("health")
		if hp != null:
			t.set("health", float(hp) - damage)
	hit_landed.emit(damage, t)
	var sfx := "punch_hit"
	if kind == "kick": sfx = "kick_hit"
	elif kind == "heavy": sfx = "heavy_hit"
	Audio.play_at(sfx, t.global_position, randf_range(0.92, 1.08))
	if player.camera_rig: player.camera_rig.shake(clampf(damage * 0.05, 0.15, 0.8))
	# Hitstop: freeze animation briefly for weight.
	# Scaled to the damage so a jab and a heavy read differently, and always
	# restored - the old version could leave time_scale at 0.55 forever if the
	# player died mid-freeze.
	_do_hitstop(clampf(0.035 + damage * 0.0022, 0.035, 0.095), 0.42)
	Game.add_heat(damage * 0.12)
	Events.record("combat_hit", {"kind": kind, "damage": damage})

## Hitstop that cannot leak. Uses a token so overlapping calls do not fight
## each other, and guarantees restoration.
var _hitstop_token := 0
func _do_hitstop(duration: float, scale: float) -> void:
	_hitstop_token += 1
	var mine := _hitstop_token
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if mine == _hitstop_token:
		Engine.time_scale = 1.0

func _dodge() -> void:
	var stats: Dictionary = Game.discipline_stats()
	var cost := 14.0 if Game.active_discipline != "drunken" else 6.0
	if Game.stamina < cost * 0.6: return
	Game.stamina = maxf(0.0, Game.stamina - cost)
	_dodge_time = 0.42
	_counter_window = 0.55
	Audio.play_at("dodge", player.global_position, randf_range(0.9, 1.1), -6.0)
	if player.rig != null: player.rig.play("roll", 1.4)
	# Drunken gives real distance; others give a short hop.
	var dist := 4.2 if Game.active_discipline == "drunken" else 2.8
	var dir: Vector3 = -player.global_transform.basis.z * -1.0
	if player.move_dir.length() > 0.1: dir = player.move_dir
	var tw := create_tween()
	tw.tween_property(player, "global_position", player.global_position + dir.normalized() * dist, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# i-frames are handled by enemy AI reading this flag
	player.set_meta("invulnerable_until", Time.get_ticks_msec() / 1000.0 + 0.34)

func _shoot() -> void:
	var wid: String = Game.equipped_weapon
	if not Content.WEAPONS.has(wid): return
	var w: Dictionary = Content.WEAPONS[wid]
	if w["kind"] != "gun": return
	if _gun_cooldown > 0.0: return
	var mag := int(Game.ammo.get(wid, 0))
	if mag <= 0:
		_reload()
		return
	Game.consume_ammo(wid)
	_gun_cooldown = 1.0 / float(w["speed"])
	var sfx: String = {"pistol": "gun_pistol", "smg": "gun_smg", "shotgun": "gun_shotgun"}.get(wid, "gun_pistol")
	Audio.play_at(sfx, player.global_position, randf_range(0.95, 1.05), 2.0)
	if player.camera_rig: player.camera_rig.shake(0.5)
	Game.add_heat(float(w["noise"]) * 0.5)
	if player.rig != null: player.rig.play("shoot", 1.4)
	for t in targets:
		if not is_instance_valid(t): continue
		if player.global_position.distance_to(t.global_position) <= float(w["reach"]):
			_apply_hit(t, float(w["damage"]), "punch")
			break

func _reload() -> void:
	var wid: String = Game.equipped_weapon
	if not Content.WEAPONS.has(wid): return
	var w: Dictionary = Content.WEAPONS[wid]
	if w["kind"] != "gun": return
	var mag_size := int(w["mag"])
	var have := int(Game.ammo.get(wid, 0))
	if have >= mag_size: return
	Audio.play_at("reload", player.global_position, 1.0, -4.0)
	Game.ammo[wid] = mag_size
	Game.inventory_changed.emit()
	Game.notify("Reloaded", w["name"], "ammo")

func _cycle_weapon() -> void:
	var owned: Array = Game.owned_weapons
	if owned.size() <= 1: return
	var i := owned.find(Game.equipped_weapon)
	Game.equip_weapon(owned[(i + 1) % owned.size()])

# ---------------------------------------------------------------- incoming
func notify_attacked(attacker: Node3D) -> void:
	if player == null: return
	if player.has_meta("invulnerable_until"):
		if Time.get_ticks_msec() / 1000.0 < float(player.get_meta("invulnerable_until")):
			return
	var dmg := 6.5 * randf_range(0.8, 1.15)
	if _blocking:
		dmg *= 0.25
		Audio.play_at("block", player.global_position, 1.0, -4.0)
		if player.rig: player.rig.play("hit", 0.8)
	else:
		Audio.play_at("punch_hit", player.global_position, 1.0, -6.0)
		if player.rig: player.rig.play("hit", 1.0)
		Game.add_heat(2.0)
	Game.damage(dmg, "combat")
	if player.camera_rig: player.camera_rig.shake(0.45)
