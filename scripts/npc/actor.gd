extends CharacterBody3D
## ACTOR — every human in the city (named cast + pedestrians + enemies).
## One script, role-driven behaviour: idle-talker, walker, hostile, police.
## Actors remember: they track the player's last "crime" (heat) and will react.

signal died(actor)
signal talked_to(actor)

@export var role := "neighbour"
@export var display_name := ""
@export var faction := "family"

var health := 60.0
var max_health := 60.0
var armor := 0.0
var is_dead := false
var hostile := false
var npc_id := ""
var home_district := "ash_row"
var wander_center := Vector3.ZERO
var notice_range := 16.0

var rig: Node3D
var ai: Node = null                 # enemy_ai.gd state machine (hostiles only)
var fight_data: Dictionary = {}     # archetype+tier, from archetypes.gd
var _speed := 1.35
var _state := "wander"
var _idle_timer := 1.0
var _target := Vector3.ZERO
var _attack_cd := 0.0
var _attack_range := 2.2
var _damage := 7.0
var _think := 0.0
var _blocked := false

const GRAVITY := 18.0

func setup(p: Dictionary) -> void:
	role = p.get("role", "neighbour")
	display_name = p.get("name", "")
	faction = p.get("faction", "family")
	npc_id = p.get("id", "")
	home_district = p.get("district", "ash_row")
	hostile = p.get("hostile", false)
	max_health = p.get("health", 60.0)
	health = max_health
	armor = p.get("armor", 0.0)
	_damage = p.get("damage", 7.0)
	_attack_range = p.get("range", 2.2)
	_speed = p.get("speed", 1.35)
	if hostile: add_to_group("hostile")
	add_to_group("actor")
	if npc_id != "": add_to_group("named")

func _ready() -> void:
	_build()
	_target = global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))

func _build() -> void:
	rig = Node3D.new()
	rig.name = "Rig"
	rig.set_script(load("res://scripts/character/character_rig.gd"))
	add_child(rig)
	var model_name: String = Content.CHARACTERS.get(npc_id, {}).get("model", "")
	if model_name == "":
		var ped: Dictionary = Content.PEDESTRIANS.get(role, Content.PEDESTRIANS["neighbour"])
		var models: Array = ped["models"]
		model_name = models[randi() % models.size()]
	rig.build(model_name, 0.92)
	if hostile:
		_build_ai()

	# Contact shadow — a cheap grounding cue that reads on mobile without
	# costing a real shadow map per actor.
	var shadow := MeshInstance3D.new()
	var dm := Decal.new()
	dm.size = Vector3(1.1, 0.6, 1.1)
	var tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0)])
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	dm.texture_albedo = tex
	dm.position = Vector3(0, 0.06, 0)
	add_child(dm)
	shadow.queue_free()

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.78
	shape.shape = cap
	shape.position = Vector3(0, 0.89, 0)
	add_child(shape)

func _physics_process(delta: float) -> void:
	if is_dead: return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_think -= delta
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		move_and_slide()
		return

	var dist := global_position.distance_to(player.global_position)
	if hostile and ai != null:
		if not ai.is_engaged() and dist < notice_range:
			ai.begin(player)
		ai._physical(delta)
	else:
		_civilian_ai(delta, player, dist)
	move_and_slide()
	_animate()

## Build the state machine from this actor's archetype and skill tier.
## Falls back to a plain thug if the archetype id is unknown, so a typo in
## content data degrades to a fightable enemy instead of an inert one.
func _build_ai() -> void:
	var arch: String = str(fight_data.get("id", ""))
	if arch == "":
		arch = "street_thug"
	var tier: int = int(fight_data.get("tier", 1))
	if fight_data.is_empty():
		var district_tier: int = int(Content.DISTRICTS.get(home_district, {}).get("tier", 1))
		fight_data = Archetypes.make(arch, district_tier)

	ai = load("res://scripts/systems/enemy_ai.gd").new()
	ai.name = "EnemyAI"
	add_child(ai)
	ai.setup(self, fight_data)
	ai.strike_landed.connect(_on_ai_strike)

	max_health = float(fight_data.get("health", 60.0))
	health = max_health
	armor = float(fight_data.get("armor", 0.0))
	_speed = float(fight_data.get("speed", 1.3))
	_attack_range = float(fight_data.get("range", 2.0))
	_damage = float(fight_data.get("damage", 6.5))
	display_name = str(fight_data.get("name", display_name))

## A landed strike from the AI. Damage comes from the archetype — the old path
## had a single hardcoded 6.5 for every enemy in the game, so a dock hauler hit
## exactly as hard as a lookout.
## While the AI is in a thinking state, hold a fighting stance rather than idle.
func _hold_stance() -> void:
	if rig == null or ai == null:
		return
	if ai.state == ai.S_ALERT or ai.state == ai.S_PRESS or ai.state == ai.S_SPACE:
		if rig.anim_player != null and not String(rig.anim_player.current_animation).ends_with("idle"):
			rig.play("idle", 1.0)

func _on_ai_strike(_attacker, amount: float) -> void:
	if rig != null:
		rig.play("punch_hook" if amount >= 10.0 else "punch_cross", 1.1)
	Audio.play_at("punch_swing", global_position, randf_range(0.9, 1.05), -6.0)
	await get_tree().create_timer(0.14).timeout
	if is_dead:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= _attack_range + 0.5:
		if player.combat != null:
			player.combat.notify_attacked(self, amount)

func _civilian_ai(delta: float, player, dist: float) -> void:
	# NPCs with heat nearby react: they back away, then flee.
	if Game.wanted >= 2 and dist < 12.0:
		var away: Vector3 = global_position - player.global_position
		away.y = 0
		var dir := away.normalized()
		velocity.x = move_toward(velocity.x, dir.x * 3.4, 12.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * 3.4, 12.0 * delta)
		_face_to(-away)
		if _think <= 0.0:
			_think = 3.0
			_speed = 3.4
		return
	_speed = 1.35
	if _state == "idle":
		_idle_timer -= delta
		velocity.x = move_toward(velocity.x, 0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 12.0 * delta)
		if _idle_timer <= 0.0:
			_state = "wander"
			_target = _pick_wander_point()
	elif _state == "wander":
		var to: Vector3 = _target - global_position
		to.y = 0
		if to.length() < 1.4:
			_state = "idle"
			_idle_timer = randf_range(1.5, 5.0)
			velocity.x = 0
			velocity.z = 0
		else:
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * _speed, 8.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * _speed, 8.0 * delta)
			_face_to(to)

func _pick_wander_point() -> Vector3:
	var world = get_tree().current_scene
	if world != null and world.get("builder") != null:
		var nodes: Array = world.builder.nav_nodes.get(home_district, [])
		if not nodes.is_empty():
			var center: Vector3 = world.builder.district_center(home_district)
			return center + nodes[randi() % nodes.size()]
	var base := wander_center if wander_center != Vector3.ZERO else global_position
	return base + Vector3(randf_range(-14, 14), 0, randf_range(-14, 14))

var _face_yaw := 0.0
func _face_to(dir: Vector3) -> void:
	if dir.length() < 0.01: return
	_face_yaw = lerp_angle(_face_yaw, atan2(dir.x, dir.z), 0.18)
	# Hostiles are faced by enemy_ai on the body; only civils turn the rig.
	if rig != null and ai == null:
		rig.rotation.y = _face_yaw

var _last_motion := -1.0

func _animate() -> void:
	if rig == null: return
	var spd := Vector2(velocity.x, velocity.z).length()
	var m := spd / 1.35 * 2.2
	# Calling set_motion every frame with the same value restarts the idle clip
	# constantly, which pins the mesh to its bind pose. Only react to change.
	if absf(m - _last_motion) < 0.05:
		return
	_last_motion = m
	rig.set_motion(m)

func take_hit(amount: float, _from) -> void:
	if is_dead: return
	# Let the AI decide whether this landed: it owns block and dodge.
	if ai != null and _from != null and is_instance_valid(_from):
		var dir: Vector3 = _from.global_position - global_position
		var res: Dictionary = ai.on_hit(amount, dir)
		if bool(res.get("blocked", false)):
			amount = float(res.get("damage", 0.0))
			if amount <= 0.5:
				return
	health -= amount
	if rig != null: rig.hit_react()
	Audio.play_at("stagger", global_position, randf_range(0.95, 1.1), -4.0)
	if health <= 0.0:
		_die()
	elif not hostile:
		# A civilian who gets hit runs.
		_speed = 4.0
		_state = "wander"
		_target = global_position + (global_position - _from.global_position).normalized() * 24.0

func _die() -> void:
	is_dead = true
	remove_from_group("hostile")
	if rig != null: rig.play("death")
	Audio.play_at("down", global_position, 1.0, -2.0)
	died.emit(self)
	# Ragdoll-free corpse: settle to the ground, fade, remove.
	var tw := create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(rig, "scale", Vector3(0.01, 0.01, 0.01), 1.2)
	tw.tween_callback(queue_free)
	if get_tree().get_first_node_in_group("player"):
		Game.stats["fights_won"] = int(Game.stats.get("fights_won", 0)) + 1
		Game.add_xp(35)
		if int(Game.stats["fights_won"]) == 1:
			Game.unlock_achievement("first_blood")

func talk() -> Dictionary:
	var cid := npc_id
	var line := ""
	if Content.CHARACTERS.has(cid):
		line = _line_for(cid)
	Game.add_relationship(cid, 1)
	Game.stats["npcs_talked"] = int(Game.stats.get("npcs_talked", 0)) + 1
	talked_to.emit(self)
	Events.record("npc_talk", {"id": cid})
	return {"id": cid, "name": display_name if display_name != "" else Content.character_name(cid), "text": line}

func _line_for(cid: String) -> String:
	var lines := {
		"ngozi": "You're thinner than when you left. Sit. Chidi owes money to people who don't write receipts.",
		"chidi": "Marcus. I know. I know what I did. I just need one more week.",
		"tunde": "Bring it to the garage. If it rolls, I'll make it roll faster.",
		"eze": "Everyone comes through this counter eventually. You're late.",
		"sunday": "Heard your brother's name in the chair last week. Didn't like the way it was said.",
		"ada": "Whatever your brother signed, Meridian filed it as a voluntary transfer. That's not normal.",
		"kola": "You got a week before this stops being a conversation.",
		"okafor": "Mr Obi. Your brother is an asset now. Assets don't leave.",
		"nyame": "I can help you, or I can write you down. Choose faster than last time.",
		"ibrahim": "I've had your family's file for three months. Today it started making sense.",
		"bimpe": "Tell me what needs arranging. I'll tell you what it costs.",
		"mara": "Neon Mile runs on paper and loyalty. Guess which one I check.",
		"osaze": "The container at Iron Yard was never manifested. Somebody paid to unsee it.",
		"gideon": "The paperwork is clean. That's the whole point of paperwork.",
		"amaka": "I don't want the money back. I want him back.",
	}
	return lines.get(cid, "Evening. Watch yourself on the Mile after dark.")
