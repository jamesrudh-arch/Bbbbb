extends Node
## STREET NIGHT — what makes Cinder City look like a city after dark.
##
## The world already moves the sun and moon (world.gd::_apply_time), but moving
## the sun alone gives you a grey city at midnight: shopfronts go flat, glass
## goes black, and the only light is a weak moon. What actually sells night is
## emitted light — signs, interiors, headlights, windows — plus a small number
## of warm pools on the pavement, and everything else falling away into blue.
##
## Two hard constraints shape the design:
##
##  1. iPhone. Real-time lights are the single most expensive thing in a mobile
##     frame. Every light added here is `shadow_enabled = false` and the total
##     is capped; the illuminance comes from emissive materials, which cost the
##     same as any other material. A district gets pools of light, not lamps.
##  2. Time of day. Everything is built once at load and then only its energy is
##     animated, so midnight-to-noon costs no allocation.

## Total unshadowed lights per district. Godot mobile renders these in one pass -
## past roughly this many the fragment cost on an A-series GPU climbs faster than
## the picture improves.
const MAX_POOLS_PER_DISTRICT := 8

## When the sign glow ramps. Full daytime = 0 glow, full night = 1.
const NIGHT_START := 18.2    # 18:12, sunset in this city's latitude
const NIGHT_END := 6.4       # 06:24, first light

var _pools: Array[OmniLight3D] = []
var _night := 0.0
var _rng := RandomNumberGenerator.new()

# --------------------------------------------------------------- public API

## Scatter warm pools along the street frontages of one district. `center` is the
## district origin, `span` the half-extent of its built area. Lights are parented
## to `parent` so they die with the district.
func build(parent: Node3D, center: Vector3, span: float, seed_value: int) -> void:
	if parent == null:
		return
	_rng.seed = seed_value
	# Pools sit on the four street lines the city builder lays down (a 40 m block
	# pitch), so light actually falls on pavement rather than inside blocks.
	for i in MAX_POOLS_PER_DISTRICT:
		var along := _rng.randf_range(-span, span)
		var axis := _rng.randi_range(0, 3)
		var offset := 40.0 * (1.0 if _rng.randf() < 0.5 else -1.0)
		var pos: Vector3 = center
		match axis:
			0: pos += Vector3(along, 5.6, offset * 0.5 - 8.0)
			1: pos += Vector3(along, 5.6, offset * 0.5 + 8.0)
			2: pos += Vector3(offset * 0.5 - 8.0, 5.6, along)
			_: pos += Vector3(offset * 0.5 + 8.0, 5.6, along)
		var l := OmniLight3D.new()
		l.name = "NightPool%d" % i
		# Sodium-orange streetlight, not white: this is the colour of the light
		# these streets would actually be lit with.
		l.light_color = Color(1.0, 0.74, 0.46)
		l.omni_range = 17.0
		l.omni_attenuation = 1.25
		l.shadow_enabled = false
		l.light_energy = 0.0          # ramped by set_night()
		l.position = pos
		parent.add_child(l)
		_pools.append(l)

## Set the night factor, 0 = full day, 1 = full night. Called by world.gd on
## every clock tick; cheap by design.
func set_night(v: float) -> void:
	_night = clampf(v, 0.0, 1.0)
	# Square the ramp so the lights come on as dusk deepens rather than
	# switching on at a threshold, which is what makes dusk look wrong.
	var e := _night * _night
	for l in _pools:
		if is_instance_valid(l):
			l.light_energy = 2.4 * e

func night_factor() -> float:
	return _night

func pool_count() -> int:
	return _pools.size()

## Night factor for a given clock hour, so the world and the HUD agree.
static func factor_for_hour(h: float) -> float:
	if h >= NIGHT_END and h <= NIGHT_START:
		return 0.0
	if h > NIGHT_START:
		# Dusk: full darkness ~1.5 h after sunset.
		return clampf((h - NIGHT_START) / 1.5, 0.0, 1.0)
	# Dawn: darkness fades over the hour before first light.
	return clampf((NIGHT_END - h) / 1.0, 0.0, 1.0)
