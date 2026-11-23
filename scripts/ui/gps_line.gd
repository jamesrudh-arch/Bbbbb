extends Node3D
## GPS LINE — the navigation route drawn on the road itself.
##
## Takes the world-space waypoints the world map already computes and lays a
## glowing gold ribbon along the asphalt, arcing toward the next turn. Rebuilds
## when the route changes or the player drifts more than OFF_ROUTE metres off it.

const OFF_ROUTE := 12.0
const WIDTH := 0.55
const LIFT := 0.055          # sits just above the tarmac, no z-fighting
const ARROW_SPACING := 11.0

var world: Node3D = null
var _route: Array = []
var _mesh: MeshInstance3D
var _arrows: Node3D
var _im: ImmediateMesh
var _mat: StandardMaterial3D
var _refresh := 0.0
var _last_player := Vector3.INF

func setup(w: Node3D) -> void:
	world = w
	_im = ImmediateMesh.new()
	_mesh = MeshInstance3D.new()
	_mesh.mesh = _im
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.96, 0.78, 0.30, 0.80)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.80, 0.34)
	_mat.emission_energy_multiplier = 1.6
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh.material_override = _mat
	add_child(_mesh)

	_arrows = Node3D.new()
	add_child(_arrows)

func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = 0.30
	var p: Vector3 = world.player.global_position
	# Only rebuild when the route changed or we drifted off it.
	var drifted := _last_player == Vector3.INF or _dist_to_route(p) > OFF_ROUTE
	var current: Array = world.hud.map_route() if world.hud != null else []
	if current.size() != _route.size():
		drifted = true
	if not drifted:
		return
	_route = current.duplicate()
	_last_player = p
	_rebuild()

func _dist_to_route(p: Vector3) -> float:
	var best := 1e9
	for q in _route:
		best = minf(best, Vector2(q.x - p.x, q.z - p.z).length())
	return best

# -------------------------------------------------------------------- geometry
func _rebuild() -> void:
	_im.clear_surfaces()
	for c in _arrows.get_children():
		c.queue_free()
	if _route.size() < 2:
		return

	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var half := WIDTH * 0.5
	for i in _route.size():
		var p: Vector3 = _route[i]
		var dir: Vector3
		if i == 0:
			dir = (_route[1] - p)
		elif i == _route.size() - 1:
			dir = (p - _route[i - 1])
		else:
			dir = ((_route[i + 1] - _route[i - 1]))
		dir.y = 0.0
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var side := Vector3(-dir.z, 0.0, dir.x) * half
		var a := p + side + Vector3(0, LIFT, 0)
		var b := p - side + Vector3(0, LIFT, 0)
		_im.surface_set_normal(Vector3.UP)
		_im.surface_add_vertex(a)
		_im.surface_set_normal(Vector3.UP)
		_im.surface_add_vertex(b)
	_im.surface_end()

	_build_arrows()

## Chevrons along the route, pointing the way the player must travel.
func _build_arrows() -> void:
	var travelled := 0.0
	var next := ARROW_SPACING
	for i in range(1, _route.size()):
		var a: Vector3 = _route[i - 1]
		var b: Vector3 = _route[i]
		var seg := a.distance_to(b)
		while travelled + seg >= next and seg > 0.01:
			var t := (next - travelled) / seg
			var pos := a.lerp(b, t)
			_arrow_at(pos, (b - a).normalized())
			next += ARROW_SPACING
		travelled += seg

func _arrow_at(pos: Vector3, dir: Vector3) -> void:
	var m := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.75, 0.46, 0.02)
	m.mesh = pm
	m.material_override = _mat
	m.position = pos + Vector3(0, LIFT + 0.01, 0)
	# PrismMesh points up +Y; lay it flat and aim it down the road.
	var up := Vector3.UP
	var basis := Basis.looking_at(-dir, up)
	m.transform.basis = basis * Basis(Vector3.RIGHT, deg_to_rad(-90.0))
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrows.add_child(m)
