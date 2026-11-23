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
	if hostile:
		_hostile_ai(delta, player, dist)
	else:
		_civilian_ai(delta, player, dist)
	move_and_slide()
	_animate()

func _hostile_ai(delta: float, player, dist: float) -> void:
	# Pursue and swing. Police also chase while the player carries heat.
	var stopping := _attack_range * 0.92
	var to: Vector3 = player.global_position - global_position
	to.y = 0
	if dist > stopping:
		var dir := to.normalized()
		velocity.x = move_toward(velocity.x, dir.x * _speed * 1.6, 10.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * _speed * 1.6, 10.0 * delta)
		_face_to(to)
	else:
		velocity.x = move_toward(velocity.x, 0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 16.0 * delta)
		_face_to(to)
		if _attack_cd <= 0.0:
			_attack_cd = randf_range(1.7, 2.6)
			_swing(player)

func _swing(player) -> void:
	if rig != null: rig.play("punch", 1.1)
	Audio.play_at("punch_swing", global_position, randf_range(0.9, 1.05), -6.0)
	await get_tree().create_timer(0.16).timeout
	if is_dead: return
	if global_position.distance_to(player.global_position) <= _attack_range:
		if player.combat != null:
			player.combat.notify_attacked(self)

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
	if rig != null: rig.rotation.y = _face_yaw

func _animate() -> void:
	if rig == null: return
	var spd := Vector2(velocity.x, velocity.z).length()
	rig.set_motion(spd / 1.35 * 2.2)

func take_hit(amount: float, _from) -> void:
	if is_dead: return
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
