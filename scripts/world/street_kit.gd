extends Node3D
## STREET KIT — the authored vocabulary of a Cinder City street.
##
## Research basis (all measured from sources, not recalled):
##  - Danfo minibuses are YELLOW with DOUBLE BLACK STRIPES and carry painted
##    slogans ("No condition is permanent", "Suru lere", "Ese oluwa", "Mafo").
##    They are ~45% of vehicles on Lagos roads.
##  - Street trading is the visible economic layer: stalls, umbrellas, grills.
##  - Informal infrastructure is repurposed: wheel rims as signposts, tyres as
##    barriers, generators bolted to walls.
##  - "Lagos is intensely visual" - signage and colour carry status.
##  - Game-city research: props are the silent storytellers; density must be
##    tuned (too few = unfinished, too many = noise); each district needs its
##    own architectural style, lighting colour and dominant hue.
##
## Every prop here is built from primitives with deliberate colour and
## proportion. That is a real constraint of this project (no bespoke meshes),
## so the goal is that a street READS as Lagos at a glance, not that each
## individual prop is a hero asset.

const SLOGANS := [
	"No Condition Is Permanent", "Suru Lere", "Ese Oluwa", "No King As God",
	"Mafo", "Oluwa Ni", "God Dey", "One Love", "Patience", "Shine Your Eyes",
]

const SHOP_NAMES := [
	"MAMA NGOZI PROVISIONS", "SUNDAY BARBER'S SALON", "BLESSED TYRE VULCANIZER",
	"CHIEF OBI COLD ROOM", "GOODLUCK PHONE REPAIR", "EKO BAKERY",
	"FAVOUR BUKA & RICE", "NEW LIFE GENERATOR SERVICE", "PA SULE PAWN",
	"AGEGE BOLT & NUT", "HOLY GHOST CHEMIST", "TUNDE MOTOR PARTS",
]

const AD_SIGNS := [
	"NO TRADING NO HAWKING", "BUY YOUR AIRTIME HERE", "COLD BEER INSIDE",
	"CHANGE YOUR TYRE NOW", "GENUINE PARTS ONLY", "MTN DATA - ALL NETWORK",
]

## Palette anchors. Lagos streets are not grey - yellow, red, blue and rust
## sit against concrete, and the weather stains everything warm.
const C_DANFO := Color(0.98, 0.78, 0.09)
const C_DANFO_STRIPE := Color(0.05, 0.05, 0.06)
const C_RUST := Color(0.52, 0.26, 0.14)
const C_CANVAS_A := Color(0.86, 0.22, 0.18)
const C_CANVAS_B := Color(0.16, 0.42, 0.72)
const C_CANVAS_C := Color(0.90, 0.86, 0.72)
const C_CONCRETE := Color(0.52, 0.50, 0.47)
const C_METAL := Color(0.34, 0.35, 0.37)
const C_PLASTIC := Color(0.14, 0.20, 0.30)

var _rng := RandomNumberGenerator.new()

func set_seed(s: int) -> void:
	_rng.seed = s

## Materials are cached and shared. Without this, every helper call creates a
## new material object, which defeats draw-call batching entirely: the renderer
## cannot merge two surfaces that use different resources even when they look
## identical. Keyed on the exact parameters that affect appearance.
var _mat_cache: Dictionary = {}

## Snap a colour to a coarse grid. Colours that differ imperceptibly can then
## share one material, which is what keeps the merged draw-call count sane.
func _q(c: Color) -> Color:
	return Color(snappedf(c.r, 0.08), snappedf(c.g, 0.08), snappedf(c.b, 0.08), 1.0)

func _mat(c: Color, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var key := "%0.4f_%0.4f_%0.4f_%0.4f_%0.3f_%0.3f" % [c.r, c.g, c.b, c.a, rough, metal]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	_mat_cache[key] = m
	return m

## Glass: dark base, but with real specular so it picks up sky and sun instead
## of sitting as a flat black rectangle.
func _glass(base: Color) -> StandardMaterial3D:
	var key := "g_%0.4f_%0.4f_%0.4f" % [base.r, base.g, base.b]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = 0.12
	m.metallic = 0.55
	m.metallic_specular = 0.85
	_mat_cache[key] = m
	return m

func _emissive(c: Color, energy: float = 2.2) -> StandardMaterial3D:
	var key := "e_%0.4f_%0.4f_%0.4f_%0.3f" % [c.r, c.g, c.b, energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	_mat_cache[key] = m
	return m

func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi

func _cyl(r: float, h: float, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi

# --------------------------------------------------------------- DANFO BUS
## The single most recognisable object in Lagos. Yellow body, double black
## stripe along the flanks, open sliding door, roof rack, painted slogan.
func danfo(pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Danfo"
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)

	var yellow := _mat(C_DANFO, 0.38, 0.15)
	var dark := _mat(C_DANFO_STRIPE, 0.5)

	# Body: van proportions, slightly tall and narrow.
	_box(Vector3(1.9, 1.55, 4.3), Vector3(0, 1.15, 0), yellow, n)
	# Cab step-down front, tucked inside the body span so it reads as a bonnet
	# rather than a block stuck on the nose.
	_box(Vector3(1.88, 0.86, 0.62), Vector3(0, 0.80, -1.92), yellow, n)
	# Double black stripes: the danfo signature.
	_box(Vector3(1.93, 0.16, 4.28), Vector3(0, 1.62, 0), dark, n)
	_box(Vector3(1.93, 0.09, 4.28), Vector3(0, 1.42, 0), dark, n)
	# Roof rack loaded with goods
	_box(Vector3(1.7, 0.10, 3.4), Vector3(0, 1.99, 0.2), _mat(C_METAL, 0.7, 0.6), n)
	for i in 3:
		_box(Vector3(_rng.randf_range(0.5, 0.9), _rng.randf_range(0.25, 0.5), 0.8),
			Vector3(_rng.randf_range(-0.5, 0.5), 2.2, -1.1 + i * 1.1),
			_mat(Color(0.35, 0.30, 0.26).darkened(_rng.randf_range(0, 0.2)), 0.9), n)
	# Windscreen + side glazing
	var glass := _mat(Color(0.12, 0.16, 0.20), 0.12, 0.4)
	_box(Vector3(1.74, 0.66, 0.06), Vector3(0, 1.34, -2.16), glass, n)
	for sx in [-0.97, 0.97]:
		_box(Vector3(0.04, 0.62, 2.75), Vector3(sx, 1.40, 0.05), glass, n)
	# Open sliding door on the kerb side (passengers hang out of it)
	_box(Vector3(0.06, 1.20, 1.15), Vector3(0.97, 1.05, -1.15),
		_mat(Color(0.08, 0.07, 0.07), 0.9), n)
	# Headlights / taillights
	for sx in [-0.62, 0.62]:
		_box(Vector3(0.34, 0.20, 0.07), Vector3(sx, 0.84, -2.20), _emissive(Color(1, 0.94, 0.75), 2.6), n)
		_box(Vector3(0.28, 0.24, 0.06), Vector3(sx, 1.05, 2.16), _emissive(Color(0.95, 0.15, 0.10), 1.8), n)
	# Wheels. A cylinder is built along +Y, so it is rotated onto the X axis to
	# become a wheel and pulled inside the body width; half of it protrudes.
	var tyre := _mat(Color(0.075, 0.075, 0.08), 0.95)
	var hub := _mat(Color(0.52, 0.52, 0.50), 0.45, 0.6)
	for wp in [Vector3(-0.86, 0.40, -1.50), Vector3(0.86, 0.40, -1.50),
			Vector3(-0.86, 0.40, 1.46), Vector3(0.86, 0.40, 1.46)]:
		var w := _cyl(0.40, 0.22, wp, tyre, n)
		w.rotation.z = PI * 0.5
		var h := _cyl(0.17, 0.235, wp, hub, n)
		h.rotation.z = PI * 0.5
	# Painted slogan on the flank. Real ones are hand-lettered in white or black
	# along the side; text must be sized to fit the 4.3 m flank or it clips.
	var sl: String = SLOGANS[_rng.randi_range(0, SLOGANS.size() - 1)]
	var sl_size: float = minf(0.26, 2.6 / maxf(1.0, float(sl.length()) * 0.60))
	for sx in [-1.0, 1.0]:
		var l := _label3d(sl, Vector3(sx * 0.97, 0.78, 0.35), n, sl_size,
			Color(0.97, 0.96, 0.92), 0.35)
		l.rotation.y = sx * PI * 0.5
	return n

# ------------------------------------------------------------------ KIOSK
## A container shop with a painted board above. The board is the thing that
## makes a street read as a place where people live.
func kiosk(pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Kiosk"
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)

	var body_col: Color = [C_CONCRETE, C_RUST, Color(0.30, 0.42, 0.34), Color(0.55, 0.42, 0.28)][_rng.randi_range(0, 3)]
	var w := _rng.randf_range(2.6, 3.4)
	var d := _rng.randf_range(2.2, 2.8)
	_box(Vector3(w, 2.5, d), Vector3(0, 1.25, 0), _mat(body_col.darkened(_rng.randf_range(0, 0.18)), 0.9), n)
	# Corrugated roof: a row of ridges, cheap and reads instantly
	var roof := _mat(C_RUST.lightened(0.1), 0.75, 0.35)
	_box(Vector3(w + 0.35, 0.08, d + 0.35), Vector3(0, 2.55, 0), roof, n)
	for i in int(w * 2.2):
		_box(Vector3(0.09, 0.10, d + 0.3),
			Vector3(-w * 0.5 + 0.2 + i * 0.45, 2.62, 0), roof, n)
	# Shopfront: dark opening with a lit interior
	_box(Vector3(w * 0.62, 1.35, 0.08), Vector3(0, 1.08, d * 0.5 + 0.02),
		_mat(Color(0.10, 0.09, 0.08), 0.9), n)
	_box(Vector3(w * 0.52, 1.15, 0.05), Vector3(0, 1.10, d * 0.5 + 0.06),
		_emissive(Color(1.0, 0.80, 0.48), 1.15), n)
	# Painted sign board above the shopfront
	var nm: String = SHOP_NAMES[_rng.randi_range(0, SHOP_NAMES.size() - 1)]
	_label3d(nm, Vector3(0, 2.05, d * 0.5 + 0.10), n, 0.26,
		Color(0.98, 0.95, 0.86), 0.0)
	return n

# ------------------------------------------------------------- STREET STALL
## Table, canopy umbrella, produce. These fill the pavement and are what makes
## a road look inhabited rather than generated.
func stall(pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Stall"
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)

	var wood := _mat(Color(0.42, 0.30, 0.18), 0.92)
	_box(Vector3(1.5, 0.08, 1.0), Vector3(0, 0.78, 0), wood, n)
	for sx in [-0.68, 0.68]:
		for sz in [-0.42, 0.42]:
			_box(Vector3(0.07, 0.78, 0.07), Vector3(sx, 0.39, sz), wood, n)
	# Produce: a bright scatter of small boxes, deliberately saturated
	var produce_cols := [Color(0.88, 0.20, 0.14), Color(0.95, 0.66, 0.10),
		Color(0.32, 0.62, 0.22), Color(0.72, 0.28, 0.55)]
	for i in 7:
		_box(Vector3(_rng.randf_range(0.14, 0.3), _rng.randf_range(0.10, 0.22), _rng.randf_range(0.14, 0.3)),
			Vector3(_rng.randf_range(-0.55, 0.55), 0.88, _rng.randf_range(-0.34, 0.34)),
			_mat(produce_cols[_rng.randi_range(0, produce_cols.size() - 1)], 0.75), n)
	# Canopy: a broad disc on a pole, striped
	var canopy_col: Color = [C_CANVAS_A, C_CANVAS_B, C_CANVAS_C][_rng.randi_range(0, 2)]
	_cyl(0.045, 2.1, Vector3(0, 1.05, 0), _mat(C_METAL, 0.6, 0.7), n)
	var c := _cyl(1.25, 0.07, Vector3(0, 2.15, 0), _mat(canopy_col, 0.8), n)
	c.scale = Vector3(1.0, 1.0, 1.0)
	return n

# -------------------------------------------------------------------- PROP
## Tyres, generators, gas cylinders, crates - the clutter that sells a street.
func clutter(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "Clutter"
	n.position = pos
	n.rotation.y = _rng.randf_range(0, TAU)
	add_child(n)
	var kind := _rng.randi_range(0, 3)
	match kind:
		0:   # tyre stack
			var tyre := _mat(Color(0.07, 0.07, 0.08), 0.95)
			for i in _rng.randi_range(2, 4):
				var t := _cyl(0.38, 0.22, Vector3(0, 0.11 + i * 0.23, 0), tyre, n)
				t.rotation.x = _rng.randf_range(-0.05, 0.05)
		1:   # generator
			_box(Vector3(0.9, 0.6, 0.55), Vector3(0, 0.3, 0),
				_mat(Color(0.72, 0.16, 0.12), 0.7, 0.3), n)
			_box(Vector3(0.25, 0.18, 0.25), Vector3(0.3, 0.68, 0), _mat(C_METAL, 0.6, 0.7), n)
		2:   # gas cylinders
			for i in _rng.randi_range(1, 3):
				_cyl(0.19, 0.62, Vector3(i * 0.42, 0.31, 0),
					_mat(Color(0.85, 0.55, 0.12), 0.6, 0.2), n)
		3:   # crates / sacks
			for i in _rng.randi_range(2, 4):
				_box(Vector3(_rng.randf_range(0.4, 0.7), _rng.randf_range(0.3, 0.55), _rng.randf_range(0.4, 0.7)),
					Vector3(_rng.randf_range(-0.4, 0.4), 0.2, _rng.randf_range(-0.4, 0.4)),
					_mat(Color(0.46, 0.36, 0.24).darkened(_rng.randf_range(0, 0.25)), 0.95), n)
	return n

# ------------------------------------------------------------------- OKADA
## Motorcycle taxi. Small, cheap, and immediately reads as West African.
func okada(pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Okada"
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	var frame := _mat(Color(0.16, 0.16, 0.18), 0.6, 0.4)
	var tyre := _mat(Color(0.06, 0.06, 0.07), 0.95)
	_box(Vector3(0.26, 0.30, 1.35), Vector3(0, 0.62, 0), frame, n)
	_box(Vector3(0.34, 0.14, 0.55), Vector3(0, 0.82, 0.15),
		_mat(Color(0.30, 0.08, 0.08), 0.8), n)   # seat
	_box(Vector3(0.55, 0.06, 0.10), Vector3(0, 0.95, -0.55), frame, n)  # bars
	for z in [-0.62, 0.62]:
		var w := _cyl(0.30, 0.12, Vector3(0, 0.30, z), tyre, n)
		w.rotation.z = PI * 0.5
	_box(Vector3(0.16, 0.14, 0.05), Vector3(0, 0.72, -0.70),
		_emissive(Color(1, 0.95, 0.8), 2.0), n)
	return n

# ---------------------------------------------------------------- SIGNAGE
## A wall-mounted board. Text is the cheapest way to make a place feel real
## and specific instead of generic.
func wall_sign(pos: Vector3, rot_y: float, text: String, w := 2.6, h := 0.7) -> Node3D:
	var n := Node3D.new()
	n.name = "WallSign"
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	_box(Vector3(w, h, 0.07), Vector3.ZERO, _mat(Color(0.12, 0.13, 0.16), 0.8), n)
	_box(Vector3(w - 0.12, h - 0.10, 0.03), Vector3(0, 0, 0.05),
		_emissive(Color(0.98, 0.94, 0.80), 0.9), n)
	_label3d(text, Vector3(0, 0, 0.09), n, minf(h * 0.55, 0.30), Color(0.08, 0.08, 0.10), 0.0)
	return n

func _label3d(text: String, pos: Vector3, parent: Node3D, size: float,
		col: Color, outline: float) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 64
	l.pixel_size = size * 0.0125
	l.modulate = col
	l.outline_size = int(outline * 32)
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.double_sided = true
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.shaded = false
	parent.add_child(l)
	return l

# ------------------------------------------------------------- STREET TYPES
## Density and content are tuned per street type. This is the "batch" unit:
## each type is a coherent set of choices, so streets differ from each other
## rather than being random soup.
enum StreetType { MARKET, TRANSIT, RESIDENTIAL, INDUSTRIAL, CORPORATE, NIGHTLIFE }

func populate_street(origin: Vector3, dir: Vector3, length: float, type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Street"
	root.position = origin
	add_child(root)   # street root lives under the kit for the whole district
	var t := 0.0
	match type:
		StreetType.MARKET:
			# Dense: stalls every ~7 m, kiosks every ~16 m, danfo pulled over.
			while t < length:
				var s1: float = 1.0 if _rng.randf() < 0.58 else -1.0
				var p := dir * t + _lateral(dir) * (s1 * _rng.randf_range(6.7, 8.0))
				root.add_child(_reparent(stall(p, _face(dir) * s1)))
				if _rng.randf() < 0.35:
					root.add_child(_reparent(clutter(p + dir * 1.6)))
				# a second, sparser rank on the opposite kerb
				if _rng.randf() < 0.45:
					var p2 := dir * (t + _rng.randf_range(1.0, 4.0)) + _lateral(dir) * (-s1 * _rng.randf_range(6.8, 8.1))
					root.add_child(_reparent(stall(p2, _face(dir) * -s1)))
				t += _rng.randf_range(6.0, 9.0)
			var k := 0.0
			while k < length:
				var ks: float = 1.0 if _rng.randf() < 0.62 else -1.0
				root.add_child(_reparent(kiosk(dir * k + _lateral(dir) * (ks * 8.4), _face(dir) * ks)))
				k += _rng.randf_range(14.0, 20.0)
			root.add_child(_reparent(danfo(dir * (length * 0.45) + _lateral(dir) * 5.2, _face(dir))))
			root.add_child(_reparent(danfo(dir * (length * 0.72) + _lateral(dir) * 5.4, _face(dir) + PI)))
		StreetType.TRANSIT:
			# Danfo corridor: buses nose to tail, fewer stalls.
			while t < length:
				root.add_child(_reparent(danfo(dir * t + _lateral(dir) * 5.0, _face(dir) + PI)))
				t += _rng.randf_range(9.0, 13.0)
			t = 0.0
			while t < length:
				root.add_child(_reparent(clutter(dir * t + _lateral(dir) * 7.2)))
				t += _rng.randf_range(10.0, 16.0)
			root.add_child(_reparent(wall_sign(dir * (length * 0.5) + _lateral(dir) * 9.5,
				_face(dir), AD_SIGNS[0], 3.4, 0.8)))
		StreetType.RESIDENTIAL:
			# Quieter: fewer props, more clutter, okada parked.
			while t < length:
				root.add_child(_reparent(clutter(dir * t + _lateral(dir) * 6.8)))
				t += _rng.randf_range(12.0, 20.0)
			t = length * 0.3
			while t < length:
				root.add_child(_reparent(okada(dir * t + _lateral(dir) * 6.3,
					_face(dir) + _rng.randf_range(-0.4, 0.4))))
				t += _rng.randf_range(18.0, 30.0)
		StreetType.INDUSTRIAL:
			while t < length:
				root.add_child(_reparent(clutter(dir * t + _lateral(dir) * 6.5)))
				t += _rng.randf_range(7.0, 12.0)
			root.add_child(_reparent(wall_sign(dir * (length * 0.35) + _lateral(dir) * 9.0,
				_face(dir), SHOP_NAMES[9], 3.0, 0.7)))
			root.add_child(_reparent(okada(dir * (length * 0.6) + _lateral(dir) * 5.4, _face(dir))))
		StreetType.CORPORATE:
			# Restrained: almost no street trade, a couple of signs.
			root.add_child(_reparent(wall_sign(dir * (length * 0.5) + _lateral(dir) * 9.2,
				_face(dir), AD_SIGNS[5], 3.2, 0.75)))
			root.add_child(_reparent(danfo(dir * (length * 0.8) + _lateral(dir) * 5.2, _face(dir))))
		StreetType.NIGHTLIFE:
			while t < length:
				var ns: float = 1.0 if _rng.randf() < 0.5 else -1.0
				root.add_child(_reparent(stall(dir * t + _lateral(dir) * (ns * _rng.randf_range(6.6, 7.8)),
					_face(dir) * ns)))
				t += _rng.randf_range(8.0, 12.0)
			t = length * 0.2
			while t < length:
				root.add_child(_reparent(okada(dir * t + _lateral(dir) * 5.5, _face(dir))))
				t += _rng.randf_range(12.0, 20.0)
			root.add_child(_reparent(wall_sign(dir * (length * 0.55) + _lateral(dir) * 9.0,
				_face(dir), AD_SIGNS[3], 3.0, 0.75)))
	return root

func _lateral(dir: Vector3) -> Vector3:
	return Vector3(-dir.z, 0.0, dir.x).normalized()

func _face(dir: Vector3) -> float:
	return atan2(dir.x, dir.z) + PI * 0.5

## Move a prop off the kit and under the street root. Each prop builder adds
## itself to the kit when constructed, so anything that wants it elsewhere must
## reparent rather than add again.
func _reparent(n: Node3D) -> Node3D:
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	return n

# ============================================================ street chassis
## The street's own geometry: asphalt, kerb, paving, drains, road wear. Props
## on a bare plane never read as a street no matter how many there are; this
## lays the ground the props sit in. Sizes follow the city's 12 m road and 3 m
## sidewalk so authored streets drop into the existing grid.
const CH_ROAD_W := 12.0
const CH_WALK_W := 3.0
const CH_KERB_H := 0.16
## Frontage depth cap. Keeps a street's footprint predictable when streets are
## assembled into blocks: deeper than this and parallel streets overlap.
const MAX_DEPTH := 10.0

## Thin wrapper over the existing _box so chassis code can pass colours.
func _cbox(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rough := 0.9) -> MeshInstance3D:
	return _box(size, pos, _cmat(col, rough), parent)

func _cmat(col: Color, rough := 0.9) -> StandardMaterial3D:
	# must share the cache, or every paving joint and road patch becomes its own
	# material and the bake cannot merge the chassis at all
	return _mat(_q(col), rough)

## Build the street chassis along `dir` for `length`. Returns the root.
func chassis(origin: Vector3, dir: Vector3, length: float, type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Chassis"
	root.position = origin
	root.rotation.y = atan2(dir.x, dir.z) - PI * 0.5
	add_child(root)

	var half := length * 0.5

	# Asphalt running down the middle.
	_cbox(root, Vector3(length, 0.10, CH_ROAD_W), Vector3(0, 0.05, 0), Color(0.185, 0.19, 0.205), 0.88)

	# Kerbs and paving both sides. Slightly warm concrete, not pure grey.
	var concrete := Color(0.56, 0.545, 0.505)
	var concrete_dark := Color(0.44, 0.43, 0.40)
	for side in [-1.0, 1.0]:
		var z: float = side * (CH_ROAD_W * 0.5 + CH_WALK_W * 0.5)
		_cbox(root, Vector3(length, CH_KERB_H, CH_WALK_W), Vector3(0, CH_KERB_H * 0.5, z), concrete, 0.95)
		# kerb lip facing the road
		_cbox(root, Vector3(length, CH_KERB_H + 0.06, 0.18),
			Vector3(0, (CH_KERB_H + 0.06) * 0.5, side * (CH_ROAD_W * 0.5 + 0.09)), concrete_dark, 0.92)
		# drain channel at the gutter - Lagos streets run with water after rain
		_cbox(root, Vector3(length, 0.02, 0.42),
			Vector3(0, 0.11, side * (CH_ROAD_W * 0.5 - 0.30)), Color(0.10, 0.105, 0.115), 0.6)
		# paving joints, every 1.8 m, so the walk reads at ground level
		var j := 0.0
		while j < length:
			_cbox(root, Vector3(0.05, 0.005, CH_WALK_W - 0.1),
				Vector3(-half + j, CH_KERB_H + 0.003, z), concrete_dark.lerp(concrete, 0.55), 0.95)
			j += 1.8

	# Cracks and patches: irregular dark quads on the asphalt. Cheap, and it is
	# what stops large flat surfaces looking like untextured blockout.
	var patch_col := Color(0.135, 0.14, 0.155)
	var crack_col := Color(0.105, 0.11, 0.125)
	var n := int(length * 0.55)
	for i in n:
		var px := _rng.randf_range(-half, half)
		var pz := _rng.randf_range(-CH_ROAD_W * 0.44, CH_ROAD_W * 0.44)
		var w := _rng.randf_range(0.8, 3.4)
		var d := _rng.randf_range(0.5, 2.2)
		_cbox(root, Vector3(w, 0.01, d), Vector3(px, 0.105, pz), patch_col, 0.97)
	for i in int(length * 0.35):
		var cx := _rng.randf_range(-half, half)
		var cz := _rng.randf_range(-CH_ROAD_W * 0.45, CH_ROAD_W * 0.45)
		var cl := _rng.randf_range(1.0, 4.0)
		var crack := _cbox(root, Vector3(cl, 0.012, _rng.randf_range(0.06, 0.11)),
			Vector3(cx, 0.108, cz), crack_col, 0.9)
		crack.rotation.y = _rng.randf_range(-0.5, 0.5)

	# Lane paint. Worn, so it is desaturated and broken into dashes.
	var paint := Color(0.70, 0.66, 0.50)
	var p := -half + 1.0
	while p < half:
		_cbox(root, Vector3(2.6, 0.012, 0.20), Vector3(p, 0.112, 0), paint, 0.9)
		p += 6.0

	# Painted kerb edge in the market district - seller territory markings.
	if type == StreetType.MARKET:
		var mark := Color(0.85, 0.72, 0.20)
		var mx := -half
		while mx < half:
			_cbox(root, Vector3(1.4, 0.012, 0.26), Vector3(mx, 0.113, CH_ROAD_W * 0.5 - 0.55), mark, 0.9)
			mx += 2.4

	return root

# ============================================================== SHOPHOUSE ROW
## The form that actually defines a Lagos street: narrow, deep, multi-storey
## shophouses packing the kerb, each with a shopfront at the base, an awning or
## balcony above it, tanks and AC units bolted on, and signage covering most of
## the ground floor. The facade is built face-on so it can sit along a street
## edge; `w` is frontage along the street, `d` is depth away from it.
## Name and trade are stored as pairs. A shop called "KINGSLEY PHARMACY"
## advertising "BEAUTY SALON" is the kind of detail that reads as noise; real
## signage is consistent with the trade under it.
const SHOPS := [
	["BLESSED CHIGOZIE", "PROVISION STORE"],
	["EMMANUEL & SONS", "BUY & SELL"],
	["GOODLUCK STORES", "COLD DRINKS"],
	["NA OMEGA", "ELECTRONICS"],
	["PRINCE VENTURES", "TYRE REPAIR"],
	["MAMA NNEKA", "BUKA & RICE"],
	["TEXACO COLD ROOM", "FROZEN FOODS"],
	["ADEMOLA BROS", "HARDWARE"],
	["NNAMDI ELECTRONICS", "PHONE REPAIR"],
	["SUNSHINE PROVISION", "WAEC SCRATCH CARD"],
	["DIVINE FAVOUR", "TAILORING"],
	["BRIGHT STAR SALON", "BARBING SALON"],
	["IFEOMA TEXTILES", "FABRICS"],
	["KINGSLEY PHARMACY", "CHEMIST"],
	["OGA BISI MOTORS", "AUTO PARTS"],
	["CHINEDU PHONE", "ACCESSORIES"],
	["HAPPY DAY BUKA", "PEPPER SOUP"],
	["QUEEN ESTHER", "BEAUTY SALON"],
	["UZO PLAZA", "SHOPS & OFFICES"],
	["MALLAM SULE", "EXPORT GARRI"],
]

func _pick(a: Array) -> String:
	return str(a[_rng.randi_range(0, a.size() - 1)])

## paint: the building's body colour. Streets read as a place from having their
## own restricted palette rather than full-spectrum noise, so callers pass the
## district's paint set in.
##
## Massing matters more than detail. The ground floor is INSET by RECESS and the
## upper storeys oversail it, which produces a real shadowed arcade at eye level
## and a cornice line to read against the sky. Details are then mounted on real
## surfaces rather than floating in front of one flat face.
const RECESS := 0.62

func shophouse(pos: Vector3, rot_y: float, w: float, d: float, floors: int,
		paint: Color, accent: Color, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = "Shophouse"
	n.position = pos
	n.rotation.y = rot_y
	if parent != null:
		parent.add_child(n)
	else:
		add_child(n)

	var fh := 3.3
	var h := float(floors) * fh
	var body_mat := _mat(_q(paint), 0.86, 0.02)
	var trim_mat := _mat(_q(paint.lightened(0.15)), 0.9)
	var shade_col: Color = paint.darkened(0.30)
	var shade_mat := _mat(_q(shade_col), 0.95)
	var deep_shade: Color = shade_col.darkened(0.25)
	var deep_mat := _mat(_q(deep_shade), 0.97)
	var plinth_col: Color = shade_col.darkened(0.20)
	var plinth_mat := _mat(_q(plinth_col), 0.96)

	# --- COLLISION ---------------------------------------------------------
	# A building with no collision is a stage flat: the player walks straight
	# through it and the city stops being a place. One box for the whole mass,
	# offset to match whichever massing this storey count produces.
	var solid := StaticBody3D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	var cshape := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(w, h, d)
	cshape.shape = cbox
	cshape.position = Vector3(0, h * 0.5, -d * 0.5)
	solid.add_child(cshape)
	n.add_child(solid)

	# --- MASSING -----------------------------------------------------------
	# Ground floor: set back, so the upper floors cast a shadow over it.
	var ground_d := d - RECESS
	if floors <= 1:
		# Single-storey shops have no oversail; instead the parapet does the work.
		_box(Vector3(w, h, d), Vector3(0, h * 0.5, -d * 0.5), body_mat, n)
	else:
		_box(Vector3(w, fh, ground_d), Vector3(0, fh * 0.5, -RECESS - ground_d * 0.5), shade_mat, n)
		# Upper mass oversails the recess.
		_box(Vector3(w, h - fh, d), Vector3(0, fh + (h - fh) * 0.5, -d * 0.5), body_mat, n)
		# Soffit: the underside of the oversail, a distinct dark plane. This is
		# the single most important surface for selling the arcade.
		_box(Vector3(w, 0.10, RECESS), Vector3(0, fh - 0.05, -RECESS * 0.5), deep_mat, n)
		# Column at each end holding the oversail up.
		for cx in [-w * 0.5 + 0.26, w * 0.5 - 0.26]:
			_box(Vector3(0.44, fh, 0.44), Vector3(cx, fh * 0.5, -0.22), body_mat, n)

	# Plinth - a darker skirting at pavement level, stops the base meeting the
	# ground in a hard unbroken line.
	_box(Vector3(w + 0.16, 0.42, ground_d + 0.16), Vector3(0, 0.21, -RECESS - ground_d * 0.5), plinth_mat, n)

	# --- SHOPFRONT (inside the recess) -------------------------------------
	var front_z := -RECESS + 0.02
	var shop_w := w - 1.0
	if floors <= 1:
		front_z = 0.02
		shop_w = w - 0.8
	var door_w := 1.0
	var door_x := _rng.randf_range(-shop_w * 0.30, shop_w * 0.30)
	# The doorway is genuinely open: a dark void, not a painted rectangle.
	_box(Vector3(door_w, 2.30, 0.10), Vector3(door_x, 1.15, front_z + 0.01), _mat(Color(0.09, 0.08, 0.075), 0.96), n)
	# door leaf, slightly ajar, so the opening is not a flat black rectangle
	_box(Vector3(door_w * 0.94, 2.22, 0.05), Vector3(door_x, 1.11, front_z + 0.09),
		_mat(Color(0.26, 0.22, 0.17), 0.85), n)
	# Interior back wall, dim, so the void has depth rather than being a hole.
	_box(Vector3(shop_w, 2.4, 0.10), Vector3(0, 1.2, front_z - 1.9),
		_mat(Color(0.14, 0.12, 0.10), 0.95), n)
	if _rng.randf() < 0.62:
		var win_w: float = minf(shop_w - door_w - 0.5, 4.6)
		if win_w > 1.2:
			var wx: float = door_x + (win_w + door_w) * 0.5 * (-1.0 if door_x > 0.0 else 1.0)
			_box(Vector3(win_w, 1.85, 0.06), Vector3(wx, 1.5, front_z), _emissive(Color(0.96, 0.88, 0.66), 0.5), n)
			# security grille in front of the glass
			var bars := clampi(int(win_w / 0.55), 3, 8)
			for bi in bars:
				var bx := wx - win_w * 0.5 + 0.22 + bi * (win_w - 0.44) / maxf(1.0, float(bars - 1))
				_box(Vector3(0.04, 1.85, 0.04), Vector3(bx, 1.5, front_z + 0.06),
					_mat(Color(0.13, 0.13, 0.14), 0.7), n)

	# Ground-floor filler: roller shutter boxes, step, meter box, notices. An
	# empty plane at eye level is the single biggest giveaway of a blockout.
	var filler: float = shop_w * 0.5
	if _rng.randf() < 0.65:
		var sh_w: float = _rng.randf_range(0.7, 1.5)
		var sh_x: float = -shop_w * 0.5 + sh_w * 0.5 + 0.15
		if absf(sh_x - door_x) > 0.9:
			_box(Vector3(sh_w, 2.10, 0.07), Vector3(sh_x, 1.05, front_z + 0.02),
				_mat(Color(0.36, 0.37, 0.38), 0.72, 0.3), n)
			# horizontal corrugations
			var shy := 0.20
			while shy < 2.05:
				_box(Vector3(sh_w - 0.05, 0.035, 0.075), Vector3(sh_x, shy, front_z + 0.03),
					_mat(Color(0.26, 0.27, 0.28), 0.7, 0.35), n)
				shy += 0.17
	# door step
	_box(Vector3(door_w + 0.34, 0.13, 0.34), Vector3(door_x, 0.065, front_z + 0.16),
		_mat(Color(0.50, 0.49, 0.46), 0.95), n)
	# electrical meter / small notice boards on the pillar faces
	for mi in _rng.randi_range(0, 2):
		var mx: float = _rng.randf_range(-shop_w * 0.48, shop_w * 0.48)
		_box(Vector3(0.34, 0.46, 0.07), Vector3(mx, _rng.randf_range(0.9, 2.1), front_z + 0.02),
			_mat(Color(0.62, 0.60, 0.54), 0.85), n)
	# a hanging sign bracket on some, jutting over the pavement
	if _rng.randf() < 0.3:
		var hx: float = w * 0.5 - 0.32
		_box(Vector3(0.05, 0.05, 0.95), Vector3(hx, fh - 0.95, 0.45), _mat(Color(0.20, 0.20, 0.21)), n)
		_box(Vector3(0.55, 0.42, 0.05), Vector3(hx, fh - 1.28, 0.88), _mat(Color(0.90, 0.88, 0.80), 0.9), n)

	# interior floor: a lit strip just inside the doorway catches the eye and
	# gives the void depth
	_box(Vector3(door_w * 0.8, 0.04, 0.5), Vector3(door_x, 0.06, front_z - 0.3),
		_mat(Color(0.30, 0.28, 0.24), 0.9), n)

	# --- SIGNBOARD ---------------------------------------------------------
	# Fitted to the frontage with a margin, mounted flat on the fascia above the
	# shopfront. It must never exceed the building width.
	var sign_w: float = w - 0.28
	var sign_y: float = fh - 0.62
	var sign_z: float = 0.0
	if floors > 1:
		sign_z = 0.02          # on the fascia under the oversail
		sign_y = fh - 0.52
	else:
		sign_z = 0.02
		sign_y = 2.72
	_box(Vector3(sign_w, 0.74, 0.09), Vector3(0, sign_y, sign_z), _mat(Color(0.09, 0.09, 0.10), 0.88), n)
	_box(Vector3(sign_w - 0.10, 0.62, 0.035), Vector3(0, sign_y, sign_z + 0.06),
		_emissive(accent.lerp(Color(1, 1, 1), 0.12), 0.7), n)

	var shop: Array = SHOPS[_rng.randi_range(0, SHOPS.size() - 1)]
	var nm := str(shop[0])
	var trade := str(shop[1])
	# Fit text to the board. Long names on narrow frontage is exactly where
	# signage clips; scale by both board width and character count.
	var fit: float = (sign_w * 0.86) / maxf(1.0, float(nm.length()) * 0.60)
	var nm_size: float = minf(0.42, fit)
	_label3d(nm, Vector3(0, sign_y + 0.10, sign_z + 0.10), n, nm_size, Color(0.07, 0.06, 0.07), 0.6)
	_label3d(trade, Vector3(0, sign_y - 0.22, sign_z + 0.10), n, maxf(0.16, minf(0.27, nm_size * 0.72)),
		Color(0.13, 0.09, 0.09), 0.45)

	# --- AWNING ------------------------------------------------------------
	# Hung from the fascia, BELOW the signboard so it can never occlude it, and
	# shallow enough (1.05 m) that it shades the shopfront instead of hiding it.
	# Back edge is set into the wall so it cannot read as floating.
	if floors > 1 and _rng.randf() < 0.72:
		var aw_col: Color = [Color(0.74, 0.16, 0.13), Color(0.13, 0.35, 0.54),
			Color(0.88, 0.74, 0.30), Color(0.18, 0.44, 0.30),
			Color(0.90, 0.90, 0.86)][_rng.randi_range(0, 4)]
		var aw_w: float = w - 0.5
		var aw_mat := _mat(aw_col, 0.94)
		var depth := 1.05
		var slope := 0.34
		var top_y: float = sign_y - 0.50
		var outer_y: float = top_y - sin(slope) * depth
		var outer_z: float = cos(slope) * depth - 0.06
		var aw := _box(Vector3(aw_w, 0.06, depth), Vector3(0, 0, 0), aw_mat, n)
		aw.position = Vector3(0, top_y - sin(slope) * depth * 0.5, cos(slope) * depth * 0.5 - 0.05)
		aw.rotation.x = slope
		# valance hanging off the outer edge
		_box(Vector3(aw_w, 0.26, 0.04), Vector3(0, outer_y - 0.13, outer_z), _mat(aw_col.darkened(0.10), 0.94), n)
		# struts from the wall out to the outer edge
		for sx in [-aw_w * 0.40, aw_w * 0.40]:
			var st := _box(Vector3(0.04, 0.04, depth * 0.94), Vector3(0, 0, 0),
				_mat(Color(0.22, 0.21, 0.20), 0.8), n)
			st.position = Vector3(sx, top_y - sin(slope) * depth * 0.5 - 0.05, cos(slope) * depth * 0.5 - 0.05)
			st.rotation.x = slope

	# --- UPPER FLOORS ------------------------------------------------------
	for f in range(1, floors):
		var y := float(f) * fh
		var per := maxi(2, int(w / 2.1))
		for i in per:
			var x: float = -w * 0.5 + (w / float(per)) * (float(i) + 0.5)
			if _rng.randf() < 0.12: continue
			var lit := _rng.randf() < 0.5
			var wc: Color = _q(accent.lightened(0.30)) if lit else Color(0.085, 0.10, 0.13)
			# Recessed opening: a dark box sunk into the wall, so it reads as a
			# hole in the mass. Then the glass, then the surrounds.
			_box(Vector3(1.06, 1.40, 0.42), Vector3(x, y + 1.62, -0.20),
				_mat(Color(0.10, 0.11, 0.13), 0.95), n)
			if lit:
				_box(Vector3(0.94, 1.28, 0.05), Vector3(x, y + 1.62, -0.055), _emissive(wc, 1.1), n)
			else:
				_box(Vector3(0.94, 1.28, 0.05), Vector3(x, y + 1.62, -0.055), _glass(wc), n)
			# lintel above, sill below, both proud of the wall
			_box(Vector3(1.24, 0.13, 0.34), Vector3(x, y + 2.34, 0.06), trim_mat, n)
			_box(Vector3(1.20, 0.12, 0.40), Vector3(x, y + 0.90, 0.10), trim_mat, n)
			if f == 1 and _rng.randf() < 0.55:
				for bi in 3:
					_box(Vector3(0.04, 1.26, 0.04),
						Vector3(x - 0.32 + bi * 0.32, y + 1.62, 0.04), _mat(Color(0.15, 0.15, 0.16), 0.7), n)
		# Balcony with a washing line: unmistakably residential, and gives the
		# facade a horizontal at mid-height.
		if f == 1 and _rng.randf() < 0.26:
			var bw: float = w * 0.58
			_box(Vector3(bw, 0.11, 1.10), Vector3(0, y + 0.72, 0.60), _mat(Color(0.58, 0.56, 0.52), 0.9), n)
			_box(Vector3(bw, 0.66, 0.05), Vector3(0, y + 1.06, 1.12), _mat(Color(0.64, 0.62, 0.58), 0.86), n)
			for ci in 4:
				var cx2: float = -bw * 0.42 + ci * bw * 0.28
				_box(Vector3(0.045, 0.66, 0.045), Vector3(cx2, y + 1.06, 1.09), _mat(Color(0.48, 0.46, 0.43)), n)
			# a line of laundry
			var lc: Color = [Color(0.85, 0.85, 0.82), Color(0.72, 0.28, 0.24),
				Color(0.28, 0.42, 0.62), Color(0.86, 0.78, 0.42)][_rng.randi_range(0, 3)]
			for li in 3:
				_box(Vector3(0.52, 0.62, 0.02),
					Vector3(-bw * 0.22 + li * bw * 0.24, y + 1.44, 1.12), _mat(lc, 0.92), n)

	# --- ROOF --------------------------------------------------------------
	# Cornice oversailing, then parapet, then rooftop clutter. Rooflines here
	# are never clean.
	_box(Vector3(w + 0.34, 0.24, d + 0.26), Vector3(0, h + 0.04, -d * 0.5), trim_mat, n)
	_box(Vector3(w + 0.10, 0.42, d + 0.10), Vector3(0, h + 0.30, -d * 0.5), body_mat, n)
	if _rng.randf() < 0.5:
		_box(Vector3(w * 0.34, 0.34, 0.10), Vector3(0, h + 0.62, 0.02), trim_mat, n)

	var tanks := _rng.randi_range(0, 2)
	for i in tanks:
		var tx: float = _rng.randf_range(-w * 0.28, w * 0.28)
		var tz: float = _rng.randf_range(-d * 0.72, -d * 0.24)
		var tr: float = 0.51
		var th: float = 0.97
		var tank_col: Color = [Color(0.09, 0.11, 0.14), Color(0.56, 0.43, 0.13),
			Color(0.70, 0.70, 0.68)][_rng.randi_range(0, 2)]
		_cyl(tr, th, Vector3(tx, h + 0.18 + th * 0.5, tz), _mat(tank_col, 0.66), n)
		# stand
		_box(Vector3(tr * 2.1, 0.10, tr * 2.1), Vector3(tx, h + 0.20, tz), _mat(Color(0.30, 0.29, 0.28)), n)
	for i in _rng.randi_range(0, 3):
		var ax: float = _rng.randf_range(-w * 0.33, w * 0.33)
		var ay: float = _rng.randf_range(fh * 1.25, maxf(fh * 1.4, h - 0.9))
		_box(Vector3(0.76, 0.50, 0.40), Vector3(ax, ay, 0.22), _mat(Color(0.76, 0.76, 0.72), 0.62), n)
		_box(Vector3(0.58, 0.38, 0.03), Vector3(ax, ay, 0.43), _mat(Color(0.28, 0.28, 0.28)), n)
	return n

## A whole row of shophouses down one side of a street. Frontage width varies so
## the row is irregular; a couple are taller, most are 2-4 storeys. Side is
## -1 or +1 for the left or right kerb.
func shophouse_row(origin: Vector3, dir: Vector3, length: float, side: float,
		type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Row"
	root.position = origin
	root.rotation.y = atan2(dir.x, dir.z) - PI * 0.5
	add_child(root)

	var base_z: float = side * (CH_ROAD_W * 0.5 + CH_WALK_W + 0.02)
	# The facade is built on the local +Z plane, so the right-hand row (at +Z)
	# must be turned 180 degrees to face back across the street.
	var rot: float = PI if side > 0.0 else 0.0

	# Restrict the palette per street type. Two or three paint colours only.
	var paints: Array = []
	var accents: Array = []
	match type:
		StreetType.MARKET:
			paints = [Color(0.72, 0.60, 0.40), Color(0.66, 0.50, 0.36), Color(0.78, 0.70, 0.52)]
			accents = [Color(0.88, 0.30, 0.18), Color(0.92, 0.72, 0.16), Color(0.24, 0.52, 0.72)]
		StreetType.TRANSIT:
			paints = [Color(0.58, 0.56, 0.52), Color(0.50, 0.50, 0.50), Color(0.66, 0.60, 0.50)]
			accents = [Color(0.86, 0.70, 0.14), Color(0.16, 0.44, 0.62), Color(0.80, 0.24, 0.20)]
		StreetType.RESIDENTIAL:
			paints = [Color(0.70, 0.66, 0.58), Color(0.62, 0.58, 0.50), Color(0.74, 0.64, 0.56)]
			accents = [Color(0.30, 0.50, 0.40), Color(0.72, 0.44, 0.30), Color(0.36, 0.42, 0.58)]
		StreetType.INDUSTRIAL:
			paints = [Color(0.44, 0.42, 0.40), Color(0.52, 0.44, 0.36), Color(0.38, 0.38, 0.39)]
			accents = [Color(0.80, 0.50, 0.12), Color(0.62, 0.22, 0.16), Color(0.30, 0.38, 0.44)]
		StreetType.CORPORATE:
			paints = [Color(0.62, 0.64, 0.68), Color(0.54, 0.57, 0.62), Color(0.70, 0.70, 0.72)]
			accents = [Color(0.20, 0.52, 0.72), Color(0.78, 0.78, 0.80), Color(0.14, 0.34, 0.50)]
		StreetType.NIGHTLIFE:
			paints = [Color(0.42, 0.40, 0.46), Color(0.36, 0.35, 0.42), Color(0.48, 0.42, 0.44)]
			accents = [Color(0.92, 0.22, 0.62), Color(0.26, 0.72, 0.88), Color(0.86, 0.30, 0.22)]
		_:
			paints = [Color(0.68, 0.64, 0.58)]
			accents = [Color(0.80, 0.50, 0.20)]

	var t := 0.0
	while t < length - 4.0:
		var w: float = _rng.randf_range(5.4, 8.6)
		var floors := 2
		var r := _rng.randf()
		if r < 0.16: floors = 1
		elif r < 0.50: floors = 2
		elif r < 0.80: floors = 3
		elif r < 0.94: floors = 4
		else: floors = 5
		if type == StreetType.CORPORATE: floors = maxi(floors, 3)
		if type == StreetType.RESIDENTIAL: floors = mini(floors, 3)
		var w_use: float = minf(w, length - t - 0.6)
		var paint: Color = paints[_rng.randi_range(0, paints.size() - 1)]
		var accent: Color = accents[_rng.randi_range(0, accents.size() - 1)]
		var p := Vector3(t + w_use * 0.5, 0.0, base_z)
		# Depth is capped at MAX_DEPTH so the building stays inside the corridor
		# reserved for it; deeper blocks would clash with the next street over.
		shophouse(p, rot, w_use, minf(_rng.randf_range(9.0, 15.0), MAX_DEPTH), floors, paint, accent, root)
		t += w_use + _rng.randf_range(0.0, 0.45)   # party-wall gap
	return root


# ======================================================== OVERHEAD CABLES
## Every Lagos street is roofed with cables: power, cable TV, phone, illegal
## taps, sagging between poles and buildings. Their absence is conspicuous.
## Drawn as short segments following a catenary so they sag.
func _cable(a: Vector3, b: Vector3, sag: float, parent: Node3D, thick: float = 0.035) -> void:
	var segs := 9
	var mat := _mat(Color(0.055, 0.055, 0.06), 0.85)
	var prev := a
	for i in range(1, segs + 1):
		var f := float(i) / float(segs)
		var p := a.lerp(b, f)
		p.y -= sin(f * PI) * sag
		var mid := (prev + p) * 0.5
		var d := p - prev
		var seg_len := d.length()
		if seg_len > 0.01 and is_finite(seg_len):
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = thick
			cm.bottom_radius = thick
			cm.height = seg_len
			cm.radial_segments = 5
			cm.rings = 1
			mi.mesh = cm
			mi.material_override = mat
			# Cylinder axis is +Y; rotate that onto the segment direction.
			var nd := d / seg_len
			if nd.length_squared() > 0.9:   # clean, non-degenerate direction
				mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, nd)), mid)
			parent.add_child(mi)
		prev = p

## Utility pole with transformer cans and a tangle of cables.
func power_pole(pos: Vector3, rot_y: float, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = "Pole"
	n.position = pos
	n.rotation.y = rot_y
	if parent != null:
		parent.add_child(n)
	else:
		add_child(n)
	var h := 8.4
	var wood := _mat(Color(0.30, 0.26, 0.22), 0.94)
	_cyl(0.13, h, Vector3(0, h * 0.5, 0), wood, n)
	# cross arms
	for ay in [h - 0.6, h - 1.4]:
		_box(Vector3(1.9, 0.09, 0.09), Vector3(0, ay, 0), wood, n)
		for sx in [-0.78, 0.0, 0.78]:
			_cyl(0.055, 0.18, Vector3(sx, ay + 0.13, 0), _mat(Color(0.62, 0.62, 0.58), 0.4), n)
	# transformer can bolted to the side
	if _rng.randf() < 0.55:
		_cyl(0.30, 0.92, Vector3(0.26, h - 2.5, 0), _mat(Color(0.44, 0.46, 0.44), 0.6), n)
	return n

## Run cables the length of the street and across it between opposite poles.
func power_lines(origin: Vector3, dir: Vector3, length: float, type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Cables"
	root.position = origin
	root.rotation.y = atan2(dir.x, dir.z) - PI * 0.5
	add_child(root)
	var pole_z: float = CH_ROAD_W * 0.5 + CH_WALK_W - 0.35

	# Poles down both kerbs, offset from each other.
	var step_p: float = 20.0
	var t := 6.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var idx := 0
	while t < length:
		var side: float = 1.0 if idx % 2 == 0 else -1.0
		var p := Vector3(t, 0.0, side * pole_z)
		power_pole(p, 0.0, root)
		# three conductors along the street, sagging pole to pole
		var top := Vector3(t, 7.8, side * pole_z)
		var prev := prev_r if side > 0.0 else prev_l
		if prev != Vector3.ZERO:
			for k in 3:
				var off := Vector3(0, -k * 0.34, (k - 1) * 0.16)
				_cable(prev + off, top + off, 0.55, root, 0.032)
		if side > 0.0: prev_r = top
		else: prev_l = top
		t += step_p
		idx += 1

	# Cross-street spans: the mess that makes the skyline characteristic.
	var cx := 8.0
	while cx < length - 4.0:
		var a := Vector3(cx, 7.2 + _rng.randf_range(-0.5, 0.4), pole_z)
		var b := Vector3(cx + _rng.randf_range(-2.5, 2.5), 6.6 + _rng.randf_range(-0.8, 0.5), -pole_z)
		if a.distance_squared_to(b) > 0.05:
			_cable(a, b, _rng.randf_range(0.5, 1.3), root, 0.030)
		if _rng.randf() < 0.6:
			var a2 := a + Vector3(0, -0.5, 0)
			var b2 := b + Vector3(0, -0.7, 0)
			if a2.distance_squared_to(b2) > 0.05:
				_cable(a2, b2, _rng.randf_range(0.6, 1.6), root, 0.026)
		cx += _rng.randf_range(11.0, 19.0)

	# Drops from the cables into buildings, on both sides.
	var dx := 4.0
	while dx < length:
		for side in [-1.0, 1.0]:
			if _rng.randf() < 0.5:
				var a3 := Vector3(dx + _rng.randf_range(-2.0, 2.0), 6.8, side * pole_z)
				var b3 := Vector3(a3.x + _rng.randf_range(-1.0, 1.0),
					_rng.randf_range(3.0, 5.2), side * (CH_ROAD_W * 0.5 + CH_WALK_W + 0.2))
				if a3.distance_squared_to(b3) > 0.05:
					_cable(a3, b3, 0.18, root, 0.022)
		dx += _rng.randf_range(6.0, 13.0)
	return root

# ============================================================ STREET ASSEMBLY
## One call builds a complete, coherent street of a given type: chassis, both
## frontages, street furniture and the overhead cable grid. This is the unit
## that gets batched - author six of these, place them, and you have a city.
## `origin` is the start of the street centreline; `dir` points along it.
func build_street(origin: Vector3, dir: Vector3, length: float, type: int) -> Node3D:
	var street := Node3D.new()
	street.name = "StreetBuilt"
	street.position = origin
	add_child(street)

	var d := dir.normalized()
	chassis(origin, d, length, type)
	for side in [-1.0, 1.0]:
		shophouse_row(origin, d, length, side, type)
	populate_street(origin, d, length, type)
	power_lines(origin, d, length, type)
	return street

# ================================================================== BATCHING
## A hand-built street costs ~2,100 separate meshes, which is far past any
## sensible draw-call budget. Everything a street of this kind is made of is
## static, so it can be merged: one merged mesh per material. This is the step
## that turns a good-looking street into a shippable one, and it must run after
## a street is assembled and positioned.
##
## Label3D nodes are left alone - text cannot be merged into a mesh - so signage
## still costs its own draw calls. That is a deliberate, small, known cost.
## Transform of `node` relative to `ancestor`, without needing the tree.
func _local_xf(ancestor: Node3D, node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != ancestor:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf

func bake_static(root: Node) -> int:
	var by_mat := {}
	var groups: Array = []
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null: continue
			var mat: Material = mi.material_override
			if not by_mat.has(mat):
				by_mat[mat] = []
				groups.append(mat)
			by_mat[mat].append(mi)

	var baked := 0
	for mat in groups:
		var list: Array = by_mat[mat]
		var base: Transform3D = root.transform if root is Node3D else Transform3D()
		var inv := base.affine_inverse()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any := false
		for mi in list:
			var m: Mesh = mi.mesh
			var xf: Transform3D = inv * _local_xf(root, mi)
			for surf in m.get_surface_count():
				st.append_from(m, surf, xf)
				any = true
		if not any: continue
		var merged := st.commit()
		var out := MeshInstance3D.new()
		out.mesh = merged
		out.material_override = mat
		out.name = "Baked"
		root.add_child(out)
		baked += 1

	# free the originals
	for mat in groups:
		for mi in by_mat[mat]:
			if is_instance_valid(mi) and mi.get_parent() != null:
				mi.get_parent().remove_child(mi)
				mi.queue_free()
	return baked

# ============================================================ STREET LIBRARY
## Streets are authored once and then instanced across the city. Building each
## one from scratch at load meant tens of thousands of mesh nodes and minutes of
## startup; a baked street is ~100 meshes, so one cached copy per type/variant
## can be duplicated cheaply wherever it is needed. This is the "build streets
## in batches, then combine them into a city" structure.
var _library: Dictionary = {}

## Build, bake and cache a street of `type`. Returns a fresh duplicate that can
## be moved and parented freely.
func get_street(type: int, variant: int = 0, length: float = 78.0) -> Node3D:
	var key := "%d_%d_%d" % [type, variant, int(length)]
	if not _library.has(key):
		var k = load("res://scripts/world/street_kit.gd").new()
		k.set_seed(hash(key))
		add_child(k)
		k.build_street(Vector3.ZERO, Vector3(1, 0, 0), length, type)
		k.bake_static(k)
		_library[key] = k
	var src: Node3D = _library[key]
	var dup := src.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
	return dup
