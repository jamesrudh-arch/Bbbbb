extends Node3D
## WORLD — owns Cinder City at runtime: builds districts, drives the clock and
## weather, streams distant districts, tracks the player's district, and wires
## every subsystem together in a deterministic order.

@onready var builder: Node3D = $CityBuilder
@onready var world_streamer: Node = $WorldStreamer
@onready var traffic: Node = $Traffic
@onready var npcs: Node = $NPCs
@onready var police: Node = $Police
@onready var missions: Node = $Missions
@onready var interactables: Node = $Interactables
@onready var interiors: Node = $Interiors
@onready var pickups: Node = $Pickups
@onready var fx: Node3D = $FX
@onready var rain: GPUParticles3D = $Rain
@onready var sun: DirectionalLight3D = $Sun
## 0 = full day, 1 = full night. The streamer applies this to the night pools it
## creates, and re-applies it when a new district becomes visible.
var night_factor := 0.0
@onready var moon: DirectionalLight3D = $Moon
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var districts: Dictionary = {}
var _district_check_ready := false
var _clock_accum := 0.0

## Dev-only launch args (after `--`): --hour 21.5 --district neon_mile
func _dev_args() -> Dictionary:
	var out := {}
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i].begins_with("--") and i + 1 < args.size() and not args[i + 1].begins_with("--"):
			out[args[i].substr(2)] = args[i + 1]
	return out

## Push the player to open ground if the spawn would put them inside a
## building or pressed against one, so the camera is never born inside a wall.
func _find_clear_spawn(p: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var probes := [Vector3.ZERO, Vector3(7, 0, 0), Vector3(-7, 0, 0), Vector3(0, 0, 7),
		Vector3(0, 0, -7), Vector3(11, 0, 11), Vector3(-11, 0, 11), Vector3(11, 0, -11),
		Vector3(-11, 0, -11), Vector3(0, 0, 14), Vector3(14, 0, 0)]
	for off in probes:
		var blocked := false
		for a in [0.0, 1.5708, 3.1416, 4.7124]:
			var dir := Vector3(cos(a), 0.0, sin(a))
			var q := PhysicsRayQueryParameters3D.create(
				p + off + Vector3(0, 1.2, 0), p + off + Vector3(0, 1.2, 0) + dir * 3.2, 1)
			if not space.intersect_ray(q).is_empty():
				blocked = true
				break
		if not blocked:
			return p + off
	return p

func _ready() -> void:
	randomize()
	var dev := _dev_args()
	for id in Content.DISTRICT_ORDER:
		var d: Node3D = builder.build_district(id)
		add_child(d)
		districts[id] = d
		# Night light pools are NOT built here. Like the street crowd, a light in
		# a district nobody can see is pure cost: on iPhone the renderer still
		# has to consider every retained light. The streamer creates them when a
		# district first becomes visible, exactly as it does for people.

	if dev.has("hour"):
		Game.hour = float(dev["hour"])
	elif Game.hour < 7.0 or Game.hour > 19.0:
		Game.hour = 16.5
	if dev.has("district"):
		# Spawn at that district's road-centre point so the frame opens on a street.
		var dc: Vector3 = builder.district_center(str(dev["district"]))
		player.global_position = _find_clear_spawn(dc + Vector3(-40.0, 0.35, 30.0))
		player.camera_rig.yaw = 0.0   # camera behind player, looking down -Z
	else:
		player.spawn_at(Game.spawn_point)
		player.global_position = _find_clear_spawn(player.global_position)
	Game.current_district = district_of(player.global_position)
	print("[WORLD] spawn at ", player.global_position, " district=", Game.current_district)

	hud.setup(self)
	hud.set_district(Content.district_name(Game.current_district))
	world_streamer.setup(self, districts)
	traffic.setup(self, districts)
	npcs.setup(self, districts)
	police.setup(self, districts)
	missions.setup(self)
	interactables.setup(self)
	interiors.setup(self)
	pickups.setup(self)
	_apply_time()
	_apply_weather()
	Audio.start_world_audio()
	Game.notify(Content.district_name(Game.current_district), "district")

func _process(delta: float) -> void:
	# 1 real minute = 1 in-game hour.
	_clock_accum += delta
	if _clock_accum >= 1.0:
		_clock_accum = 0.0
		Game.hour += 1.0 / 60.0
		if Game.hour >= 24.0:
			Game.hour -= 24.0
			Game.day += 1
		_apply_time()
		_update_district()

func district_of(pos: Vector3) -> String:
	return builder.district_of(pos)

func _update_district() -> void:
	if not _district_check_ready:
		if player.global_position.length() < 1.0: return
		_district_check_ready = true
	var p := player.global_position
	var best := Game.current_district
	var bestd := 1e9
	for id in Content.DISTRICTS:
		var c: Vector3 = builder.district_center(id)
		var d := Vector2(p.x - c.x, p.z - c.z).length()
		if d < bestd:
			bestd = d
			best = id
	if best != Game.current_district:
		Game.current_district = best
		Game.notify(Content.district_name(best), "district")
		hud.set_district(Content.district_name(best))
		Events.record("district_enter", {"district": best})

func _apply_time() -> void:
	var h: float = Game.hour
	var arc_t = clampf((h - 6.0) / 14.0, 0.0, 1.0)
	var elevation = sin(arc_t * PI) * 1.15
	var azimuth = lerpf(-2.3, 2.3, arc_t)
	sun.rotation = Vector3(-elevation, azimuth, 0.0)
	var daylight = clampf(elevation * 1.45 + 0.05, 0.0, 1.0)
	sun.light_energy = daylight * 2.6
	sun.visible = daylight > 0.015
	var warmth = clampf(arc_t * 1.6, 0, 1)
	sun.light_color = Color(1.0, 0.78, 0.58).lerp(Color(1.0, 0.97, 0.94), warmth)
	moon.visible = daylight < 0.55
	moon.light_energy = (1.0 - daylight) * 1.25
	moon.rotation = Vector3(-0.9, azimuth + PI, 0.0)
	var env: Environment = environment.environment
	env.fog_light_color = Color(0.06, 0.075, 0.11).lerp(Color(0.55, 0.62, 0.72), daylight)
	env.fog_density = lerpf(0.011, 0.0022, daylight)
	env.background_color = Color(0.03, 0.04, 0.075).lerp(Color(0.58, 0.68, 0.84), daylight)
	env.background_energy_multiplier = lerpf(0.9, 1.15, daylight)
	env.glow_intensity = lerpf(0.85, 0.35, daylight)

	# Night art direction. The sun/moon alone gives a grey city after dark; the
	# emissive materials plus the street pools are what make it read as night.
	# One shared factor; the streamer applies it to whatever pools exist.
	night_factor = preload("res://scripts/world/street_night.gd").factor_for_hour(h)
	# Pull ambient down and blue it out as night falls, so lit shopfronts carry
	# the frame instead of a flat fill light.
	env.ambient_light_color = Color(0.30, 0.36, 0.50).lerp(Color(0.42, 0.46, 0.55), daylight)
	env.ambient_light_energy = lerpf(0.55, 1.6, daylight)
	if hud: hud.set_clock(h, Game.weather, int(lerpf(12, 31, daylight)))

func _apply_weather() -> void:
	rain.emitting = Game.weather == "rain"
	Audio.set_weather(Game.weather)

func roll_weather() -> void:
	var r = randf()
	Game.weather = "rain" if r < 0.22 else ("overcast" if r < 0.45 else "clear")
	_apply_weather()
	hud.set_clock(Game.hour, Game.weather, int(lerpf(12, 31, clampf(sin(clampf((Game.hour - 6.0) / 14.0, 0, 1) * PI), 0, 1))))

func set_time(hour: float) -> void:
	Game.hour = fmod(hour, 24.0)
	_apply_time()

func district_center(id: String) -> Vector3:
	return builder.district_center(id)
