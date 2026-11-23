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

func _ready() -> void:
	randomize()
	var dev := _dev_args()
	for id in Content.DISTRICT_ORDER:
		var d: Node3D = builder.build_district(id)
		add_child(d)
		districts[id] = d

	if dev.has("hour"):
		Game.hour = float(dev["hour"])
	elif Game.hour < 7.0 or Game.hour > 19.0:
		Game.hour = 16.5
	if dev.has("district"):
		# Spawn at that district's road-centre point so the frame opens on a street.
		var dc: Vector3 = builder.district_center(str(dev["district"]))
		player.global_position = dc + Vector3(-40.0, 0.35, 30.0)
		player.camera_rig.yaw = 0.0   # camera behind player, looking down -Z
	else:
		player.spawn_at(Game.spawn_point)
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
	var daylight = clampf(elevation * 1.15 + 0.34, 0.0, 1.0)
	# Sun was at 2.6 which blew out every wall to near-white. Sun is the KEY light;
	# ambient does the fill. Keep sun punchy, cut the ambient (below) so the scene
	# has real shadow side instead of a uniformly lit grey box city.
	sun.light_energy = daylight * 2.35
	sun.visible = daylight > 0.015
	var warmth = clampf(arc_t * 1.6, 0, 1)
	# Warmer golden hour, less clinical white at noon.
	sun.light_color = Color(1.0, 0.72, 0.46).lerp(Color(1.0, 0.94, 0.86), warmth)
	moon.visible = daylight < 0.55
	moon.light_energy = (1.0 - daylight) * 1.25
	moon.rotation = Vector3(-0.9, azimuth + PI, 0.0)
	var env: Environment = environment.environment
	# Ambient is FILL, not key. It was 1.45-1.6 which flattened every shadow.
	env.ambient_light_energy = lerpf(0.55, 1.05, daylight)
	env.fog_light_color = Color(0.05, 0.065, 0.10).lerp(Color(0.46, 0.52, 0.62), daylight)
	env.fog_density = lerpf(0.013, 0.0034, daylight)
	# Push contrast + warmth via tone curve rather than albedo.
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.10
	env.adjustment_saturation = 1.14
	env.adjustment_brightness = 1.06
	env.glow_intensity = lerpf(0.95, 0.45, daylight)
	# Sky tint follows the time of day.
	if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		var sm := env.sky.sky_material as ProceduralSkyMaterial
		sm.sky_top_color = Color(0.02, 0.03, 0.07).lerp(Color(0.20, 0.38, 0.68), daylight)
		sm.sky_horizon_color = Color(0.12, 0.11, 0.16).lerp(Color(0.80, 0.66, 0.52), daylight)
		sm.ground_horizon_color = Color(0.10, 0.09, 0.12).lerp(Color(0.66, 0.58, 0.48), daylight)
		sm.sun_angle_max = 14.0
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
