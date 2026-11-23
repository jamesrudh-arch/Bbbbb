extends Control
## MINIMAP — live top-down map that follows the player.
##
## Draws the real street grid straight from CityBuilder's BLOCK pitch, so the
## minimap can never drift out of sync with the world. Blips are resolved from
## Game/Content state each frame, and the active route from the world map is
## drawn on top so the objective is always visible without opening the map.

const RADIUS := 78.0          # on-screen circle radius, px
const VIEW_ON_FOOT := 92.0    # metres visible across the circle
const VIEW_DRIVING := 190.0   # zoom out when moving fast

var world: Node3D = null
var _pulse := 0.0
var _route: Array = []        # world-space Vector3 points
var _route_refresh := 0.0
var _zoom := VIEW_ON_FOOT

func setup(w: Node3D) -> void:
	world = w
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)

func _process(delta: float) -> void:
	_pulse += delta
	if world == null or world.player == null:
		return
	# Zoom out smoothly as the player picks up speed.
	var spd: float = world.player.velocity.length()
	var target := VIEW_ON_FOOT + clampf(spd / 22.0, 0.0, 1.0) * (VIEW_DRIVING - VIEW_ON_FOOT)
	_zoom = lerpf(_zoom, target, minf(1.0, delta * 2.4))
	_route_refresh -= delta
	if _route_refresh <= 0.0:
		_route_refresh = 0.35
		_pull_route()
	queue_redraw()

func _pull_route() -> void:
	var hud = world.hud if world != null else null
	_route = hud.map_route() if hud != null else []

# ------------------------------------------------------------------ transform
func _centre() -> Vector2:
	return Vector2(RADIUS, RADIUS)

func _to_screen(world_pos: Vector3, player_pos: Vector3) -> Vector2:
	var d := Vector2(world_pos.x - player_pos.x, world_pos.z - player_pos.z)
	return _centre() + d * (RADIUS / (_zoom * 0.5))

# --------------------------------------------------------------------- drawing
func _draw() -> void:
	var p = world.player
	if p == null:
		return
	var pp: Vector3 = p.global_position
	var c := _centre()

	# Bed
	draw_circle(c, RADIUS, Color(0.055, 0.062, 0.075, 0.94))

	# Streets: every BLOCK multiple within view. This is the real grid.
	var block := 40.0
	if world.builder != null and "BLOCK" in world.builder:
		block = float(world.builder.BLOCK)
	var reach := _zoom * 0.75
	var gx0 := int(floor((pp.x - reach) / block))
	var gx1 := int(ceil((pp.x + reach) / block))
	var gz0 := int(floor((pp.z - reach) / block))
	var gz1 := int(ceil((pp.z + reach) / block))
	var road := Color(0.16, 0.175, 0.20, 0.95)
	var road_w := maxf(1.5, (block * 0.16) * (RADIUS / (_zoom * 0.5)) * 0.5)
	for gx in range(gx0, gx1 + 1):
		var a := _to_screen(Vector3(gx * block, 0, (gz0 - 1) * block), pp)
		var b := _to_screen(Vector3(gx * block, 0, (gz1 + 1) * block), pp)
		draw_line(a, b, road, road_w)
	for gz in range(gz0, gz1 + 1):
		var a := _to_screen(Vector3((gx0 - 1) * block, 0, gz * block), pp)
		var b := _to_screen(Vector3((gx1 + 1) * block, 0, gz * block), pp)
		draw_line(a, b, road, road_w)

	# Route, drawn under the blips.
	if _route.size() > 1:
		var gold := Color(0.94, 0.76, 0.32, 0.95)
		for i in range(1, _route.size()):
			draw_line(_to_screen(_route[i - 1], pp), _to_screen(_route[i], pp), gold, 3.0)

	# Blips
	_blip_shops(pp)
	_blip_rings(pp)
	_blip_mission(pp)
	_blip_police(pp)

	# Player arrow, rotated to facing
	var yaw: float = p.camera_rig.yaw if p.camera_rig != null else 0.0
	var tri := PackedVector2Array([
		c + Vector2(0, -7).rotated(-yaw),
		c + Vector2(5.5, 6).rotated(-yaw),
		c + Vector2(-5.5, 6).rotated(-yaw),
	])
	draw_colored_polygon(tri, Color(0.97, 0.97, 0.99))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]),
		Color(0.10, 0.11, 0.13), 1.2)

	# Rim + north tick
	draw_arc(c, RADIUS, 0, TAU, 64, Color(0.42, 0.46, 0.52, 0.85), 2.0)
	var n := Vector2(0, -1).rotated(-yaw)
	draw_circle(c + n * (RADIUS - 6.0), 3.0, Color(0.94, 0.76, 0.32))

func _blip(pos: Vector3, col: Color, size: float) -> void:
	var s := _to_screen(pos, world.player.global_position)
	if s.distance_to(_centre()) > RADIUS - 3.0:
		return
	draw_circle(s, size + 1.6, Color(0.05, 0.06, 0.08, 0.9))
	draw_circle(s, size, col)

func _blip_mission(pp: Vector3) -> void:
	var text: String = ""
	if not Game.mission.is_empty():
		var obj: Dictionary = Game.current_objective()
		text = str(obj.get("target", ""))
	if text == "":
		return
	var mm = world.get("missions")
	if mm == null or not mm.has_method("target_position"):
		return
	var pos: Vector3 = mm.target_position(text)
	if pos == Vector3.INF:
		return
	# Pulsing gold diamond for the active objective.
	var s := _to_screen(pos, pp)
	var clamped := _clamp_edge(s)
	var r := 5.0 + sin(_pulse * 4.0) * 1.2
	draw_circle(clamped, r + 2.5, Color(0.05, 0.06, 0.08, 0.9))
	draw_circle(clamped, r, Color(0.95, 0.78, 0.30))

func _blip_shops(pp: Vector3) -> void:
	if world.builder == null:
		return
	for id in Content.INTERIORS:
		var info: Dictionary = Content.INTERIORS[id]
		var d: String = str(info.get("district", ""))
		if d == "":
			continue
		var pos: Vector3 = world.builder.landmark_position(id) if world.builder.has_method("landmark_position") else Vector3.INF
		if pos == Vector3.INF:
			continue
		_blip(pos, Color(0.42, 0.78, 0.50), 2.6)

func _blip_rings(pp: Vector3) -> void:
	# Ring venues are authored per district; draw one marker per district centre
	# until the venues themselves exist as world objects.
	for id in Content.DISTRICT_ORDER:
		if not Game.has_flag("ring_" + id):
			continue
		var pos: Vector3 = world.builder.district_center(id) if world.builder != null else Vector3.INF
		_blip(pos, Color(0.86, 0.36, 0.36), 3.0)

func _blip_police(pp: Vector3) -> void:
	if world.police == null:
		return
	var units: Array = world.police.units if "units" in world.police else []
	var flash := 0.55 + sin(_pulse * 8.0) * 0.35
	for u in units:
		if not is_instance_valid(u):
			continue
		_blip(u.global_position, Color(0.35, 0.62, 0.98, flash), 3.0)

## Keeps an off-screen objective visible by pinning it to the rim.
func _clamp_edge(s: Vector2) -> Vector2:
	var c := _centre()
	var d := s - c
	if d.length() <= RADIUS - 8.0:
		return s
	return c + d.normalized() * (RADIUS - 8.0)
