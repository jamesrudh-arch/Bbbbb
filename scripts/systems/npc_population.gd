extends Node
## NPC POPULATION — spawns the 16 named cast plus ~25 pedestrians across the six
## districts, on the same nav graph the player walks. Named actors hold position
## near their landmark so missions can find them by id.

const ACTOR := preload("res://scripts/npc/actor.gd")

var world: Node3D
var named: Array = []
var pedestrians: Array = []

func setup(w: Node3D, districts: Dictionary) -> void:
	world = w
	_spawn_named(districts)
	_spawn_pedestrians(districts)

func _spawn_named(districts: Dictionary) -> void:
	for cid in Content.CHARACTERS:
		var c: Dictionary = Content.CHARACTERS[cid]
		var district: String = c["home"]
		if not districts.has(district): continue
		var a := ACTOR.new()
		a.name = "NPC_" + cid
		a.setup({
			"id": cid, "name": c["name"], "role": c["role"], "faction": c["faction"],
			"district": district, "hostile": false, "health": 90.0, "speed": 1.25,
		})
		add_child(a)
		var base: Vector3 = districts[district].global_position
		a.global_position = base + _free_spot(base, 26.0)
		a.wander_center = base
		a.set_meta("interact", true)
		a.set_meta("kind", "npc")
		named.append(a)

func _spawn_pedestrians(districts: Dictionary) -> void:
	# 25 pedestrians, distributed by each district's authored population weight.
	var total := 0
	for d in Content.DISTRICTS:
		total += int(Content.DISTRICTS[d].get("population", 6))
	for district in Content.DISTRICTS:
		var weight: int = int(Content.DISTRICTS[district].get("population", 6))
		var count: int = maxi(2, int(round(25.0 * float(weight) / float(maxi(1, total)))))
		for i in count:
			if pedestrians.size() >= 25: break
			var roles: Array = []
			for r in Content.PEDESTRIANS:
				if district in Content.PEDESTRIANS[r]["districts"]: roles.append(r)
			if roles.is_empty(): roles = ["neighbour"]
			var role: String = roles[randi() % roles.size()]
			var a := ACTOR.new()
			a.setup({"role": role, "district": district, "faction": "none", "health": 50.0})
			add_child(a)
			var base: Vector3 = districts[district].global_position
			a.global_position = base + _free_spot(base, 55.0)
			a.wander_center = base
			pedestrians.append(a)

func _free_spot(center: Vector3, radius: float) -> Vector3:
	for attempt in 6:
		var a := randf() * TAU
		var r := randf_range(8.0, radius)
		var p: Vector3 = Vector3(cos(a) * r, 0.2, sin(a) * r)
		var space := get_viewport().world_3d.direct_space_state if get_viewport() != null else null
		if space == null: return p
		var q := PhysicsRayQueryParameters3D.create(center + p + Vector3(0, 6, 0), center + p + Vector3(0, -2, 0), 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty(): return p
	return Vector3(randf_range(-20, 20), 0.2, randf_range(-20, 20))

## Find a named character by id (missions call this).
# ------------------------------------------------------------------- life
## Pedestrians talk to each other and to the player's surroundings on a slow
## timer. This is what makes a street feel inhabited rather than populated.
var _bark_timer := 0.0
var _chat_timer := 0.0

func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_bark_timer -= delta
	_chat_timer -= delta

	# Ambient street line near the player.
	if _bark_timer <= 0.0:
		_bark_timer = randf_range(9.0, 17.0)
		if world.conversations != null:
			var district: String = Game.current_district
			world.conversations.ambient_bark(world.player.global_position, district)

	# Two pedestrians near each other stop and chat.
	if _chat_timer <= 0.0:
		_chat_timer = randf_range(6.0, 12.0)
		_ped_to_ped_chat()

## A pair of nearby pedestrians turn to each other and trade a short exchange.
## Cheap to run and it is most of what makes a street feel alive when you stand
## still and listen.
func _ped_to_ped_chat() -> void:
	var alive := []
	for p in pedestrians:
		if is_instance_valid(p) and not p.get("is_dead"):
			alive.append(p)
	if alive.size() < 2 or world.conversations == null:
		return
	var a = alive[randi() % alive.size()]
	var partner: Node3D = null
	var best := 3.4
	for other in alive:
		if other == a:
			continue
		var d: float = a.global_position.distance_to(other.global_position)
		if d < best:
			best = d
			partner = other
	if partner == null:
		return
	var district: String = str(Game.current_district)
	var lines: Array = world.conversations.AMBIENT.get(district, [])
	if lines.size() < 2:
		return
	var first: String = str(lines[randi() % lines.size()])
	var second: String = str(lines[randi() % lines.size()])
	if second == first:
		second = "Mm."

	# Turn them toward each other, hold briefly, then resume their wandering.
	a.set("_chat_hold", 1.6)
	partner.set("_chat_hold", 1.6)
	a.face_toward(partner.global_position)
	partner.face_toward(a.global_position)
	world.conversations.bark_spoken.emit("", first)
	if world.hud != null and world.hud.has_method("show_bark"):
		world.hud.show_bark("", first, a.global_position)

	await get_tree().create_timer(1.9).timeout
	if not is_instance_valid(partner) or not is_instance_valid(a):
		return
	if world == null or world.hud == null:
		return
	world.hud.show_bark("", second, partner.global_position)
	a.set("_chat_hold", 0.0)
	partner.set("_chat_hold", 0.0)

func find_named(cid: String) -> Node3D:
	for a in named:
		if is_instance_valid(a) and a.npc_id == cid: return a
	return null

## Spawn a hostile squad (missions / police).
func spawn_squad(center: Vector3, count: int, health: float = 70.0, damage: float = 8.0) -> Array:
	var squad := []
	for i in count:
		var a := ACTOR.new()
		a.setup({"role": "enforcer", "faction": "crew", "hostile": true,
			"health": health, "damage": damage, "speed": 1.5})
		add_child(a)
		var ang := TAU * float(i) / float(maxi(1, count))
		a.global_position = center + Vector3(cos(ang) * 6.0, 0.3, sin(ang) * 6.0)
		squad.append(a)
	return squad
