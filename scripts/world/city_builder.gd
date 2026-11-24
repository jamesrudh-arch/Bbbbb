extends Node3D
## CITY BUILDER — procedural Cinder City generator.
## Six districts on a 3x2 grid, 160 m pitch, 480 x 320 m continuous landmass.
## Every district is laid out as: ground slab -> road grid -> sidewalk lanes ->
## buildings -> street furniture -> props -> parked vehicles -> nav/drive graphs.
## Deterministic per district (seeded) so a save always reloads the same city.

# Kenney kits are authored at 1 unit = 1 m but the city kits read small, so the
# established scale factor is 10x for city geometry and 1.8x for vehicles.
## Animated pedestrians per district. Each one is a skeleton driven by a single
## shared AnimationPlayer, so the cost is the skinning, not the player. Fourteen
## is the point where a walk down a street feels populated without the GPU
## spending its frame on skinning.
const ANIMATED_CROWD := 14

const CITY_SCALE := 10.0
const VEHICLE_SCALE := 1.8

const BLOCK := 40.0          # city block pitch
const ROAD_W := 12.0         # road width
const SIDEWALK_W := 3.0

var nav_nodes: Dictionary = {}     # district -> Array[Vector3] (sidewalk graph)
var drive_graph: Dictionary = {}   # district -> Array[Vector3] (road centre graph)
var model_cache: Dictionary = {}
var _surface_cache: Dictionary = {}

# ---------------------------------------------------------------- public API
func district_center(id: String) -> Vector3:
	return Content.district_center(id)

func build_district(id: String) -> Node3D:
	var info: Dictionary = Content.DISTRICTS[id]
	var center := district_center(id)
	var root := Node3D.new()
	root.name = "District_" + id
	root.position = center
	root.set_meta("district_id", id)
	root.set_meta("palette", info["palette"])

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)

	_build_ground(root, info, rng)
	_build_roads(root, id, info, rng)
	_build_sidewalks(root, id, info, rng)
	_build_buildings(root, id, info, rng)
	_build_street_furniture(root, id, info, rng)
	_build_props(root, id, info, rng)
	_build_parked_vehicles(root, id, info, rng)
	_build_landmarks(root, id, info, rng)
	_build_streets(root, id, info, rng)
	_build_nav(root, id)
	_build_drive_graph(root, id)
	return root

# ---------------------------------------------------------------- streets
## Each district gets a street character drawn from its own identity, so the
## six areas do not all read the same. Research on game cities is consistent
## that each district needs its own dominant hue and street behaviour.
const DISTRICT_STREETS := {
	"ash_row": 0,          # MARKET
	"guttermarket": 0,     # MARKET
	"iron_yard": 3,        # INDUSTRIAL
	"cinder_line": 1,      # TRANSIT
	"vesper_heights": 4,   # CORPORATE
	"neon_mile": 5,        # NIGHTLIFE
}

func _build_streets(root: Node3D, id: String, _info: Dictionary, rng: RandomNumberGenerator) -> void:
	var kit_script = load("res://scripts/world/street_kit.gd")
	if kit_script == null: return
	var kit = kit_script.new()
	kit.name = "StreetKit"
	kit.set_seed(int(rng.randi()))
	root.add_child(kit)
	var type: int = int(DISTRICT_STREETS.get(id, 0))

	# Layout. A street occupies 38 m across: 12 m of road, 3 m of pavement each
	# side, and up to 10 m of frontage each side. Streets are therefore set on a
	# 76 m pitch so that facing frontages meet back-to-back with no gap and no
	# overlap. Each street is built full length and the junctions are simply
	# where two of them cross; nothing is cut short, because a street that stops
	# mid-block reads as a dead end.
	var half_width: float = ROAD_W * 0.5 + SIDEWALK_W + 10.0      # 19 m
	var pitch: float = half_width * 4.0                           # 76 m
	var span: float = pitch * 2.0 + 8.0                           # 160 m, overlaps at the junction
	var mid: float = pitch * 0.5

	var v := 0
	# Streets running along the X axis, on the block lines.
	for z in [-mid, mid]:
		var st: Node3D = kit.get_street(type, v, span)
		st.name = "Street_Z%d" % int(z)
		st.position = Vector3(-span * 0.5, 0.0, z)
		root.add_child(st)
		v += 1
	# Streets running along the Z axis, crossing them.
	for x in [-mid, mid]:
		var st2: Node3D = kit.get_street(type, v, span)
		st2.name = "Street_X%d" % int(x)
		st2.position = Vector3(x, 0.0, -span * 0.5)
		st2.rotation.y = PI * 0.5
		root.add_child(st2)
		v += 1

## Spawn the street crowd for one district. Called by the streamer when a
## district becomes visible, not at load: 36 skinned figures built up front for
## all six districts was enough to stop the scene from ever completing a frame.
func _spawn_street_people(root: Node3D, id: String) -> void:
	var kit = null
	for c in root.get_children():
		if c.get_script() != null and str(c.name) == "StreetKit":
			kit = c
	if kit == null:
		return
	if root.has_meta("people_spawned"):
		return
	root.set_meta("people_spawned", true)
	var type: int = int(DISTRICT_STREETS.get(id, 0))
	var span_pitch: float = 76.0
	var span: float = span_pitch * 2.0 + 8.0
	var mid: float = span_pitch * 0.5
	# One street's worth of people, on the street facing the district centre.
	# These are the static, batched figures: they cost almost nothing and they
	# make the far pavement read as inhabited.
	var from := Vector3(-span * 0.5, 0.0, -mid)
	kit.populate_people(from, Vector3(1, 0, 0), span, type)

	# Then the animated ones, on the same street. These are capped and have
	# skeletons, so they are the expensive half; the static crowd is what fills
	# the street behind them.
	var crowd = load("res://scripts/world/street_crowd.gd").new()
	crowd.name = "AnimatedCrowd"
	root.add_child(crowd)
	crowd.build(from, Vector3(1, 0, 0), span, ANIMATED_CROWD, int(hash(id)))

# ---------------------------------------------------------------- ground
func _build_ground(root: Node3D, info: Dictionary, _rng: RandomNumberGenerator) -> void:
	var pal: Dictionary = info["palette"]
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)

	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(150, 150)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pal["ground"].lightened(0.45)
	mat.roughness = 0.95
	mat.metallic = 0.0
	mesh.material_override = mat
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(150, 0.4, 150)
	shape.shape = box
	shape.position = Vector3(0, -0.2, 0)
	body.add_child(shape)

# ---------------------------------------------------------------- roads
func _build_roads(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var pal: Dictionary = info["palette"]
	var road_root := Node3D.new()
	road_root.name = "Roads"
	root.add_child(road_root)

	# Textured asphalt. A road that is one flat grey has no sense of scale - you
	# cannot tell a 3 m lane from a 30 m apron. The grain comes from a shared
	# procedural tile (surface_detail.gd), triplanar because box meshes carry no
	# UVs, so the whole city still ships zero texture files.
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.20, 0.205, 0.225)
	asphalt.roughness = 0.82
	var grain := _surface("grain")
	if grain != null:
		asphalt.albedo_texture = grain
		asphalt.uv1_triplanar = true
		asphalt.uv1_triplanar_sharpness = 4.0
		asphalt.uv1_scale = Vector3.ONE * 0.55      # tight grain at this scale
		asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	# Two cross streets per district, matching the 40 m block pitch.
	for i in [-1, 1]:
		var hz := MeshInstance3D.new()
		var b1 := BoxMesh.new()
		b1.size = Vector3(146, 0.08, ROAD_W)
		hz.mesh = b1
		hz.material_override = asphalt
		hz.position = Vector3(0, 0.04, i * BLOCK)
		road_root.add_child(hz)

		var vt := MeshInstance3D.new()
		var b2 := BoxMesh.new()
		b2.size = Vector3(ROAD_W, 0.08, 146)
		vt.mesh = b2
		vt.material_override = asphalt
		vt.position = Vector3(i * BLOCK, 0.04, 0)
		road_root.add_child(vt)

	# Lane markings
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.78, 0.74, 0.55)
	paint.emission_enabled = true
	paint.emission = Color(0.9, 0.86, 0.6)
	paint.emission_energy_multiplier = 0.25
	for i in range(-3, 4):
		var m1 := MeshInstance3D.new()
		var mb1 := BoxMesh.new()
		mb1.size = Vector3(2.4, 0.02, 0.22)
		m1.mesh = mb1
		m1.material_override = paint
		m1.position = Vector3(i * 18.0, 0.09, BLOCK)
		road_root.add_child(m1)
		var m2 := MeshInstance3D.new()
		var mb2 := BoxMesh.new()
		mb2.size = Vector3(0.22, 0.02, 2.4)
		m2.mesh = mb2
		m2.material_override = paint
		m2.position = Vector3(BLOCK, 0.09, i * 18.0)
		road_root.add_child(m2)

	# Neon when tier is high — the night identity of Vesper / Neon Mile
	if int(info["tier"]) >= 3:
		var neon := StandardMaterial3D.new()
		neon.albedo_color = pal["accent"]
		neon.emission_enabled = true
		neon.emission = pal["accent"]
		neon.emission_energy_multiplier = 2.4
		for k in 3:
			var strip := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(120, 0.18, 0.18)
			strip.mesh = sb
			strip.material_override = neon
			strip.position = Vector3(0, 6.0 + k * 7.0, -66.0)
			road_root.add_child(strip)

	# A couple of traffic signals at the intersections
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var light := Node3D.new()
			light.position = Vector3(sx * (BLOCK - 7.0), 0, sz * (BLOCK - 7.0))
			light.set_meta("traffic_light", true)
			road_root.add_child(light)
			var pole := MeshInstance3D.new()
			var pb := CylinderMesh.new()
			pb.top_radius = 0.12
			pb.bottom_radius = 0.14
			pb.height = 5.2
			pole.mesh = pb
			pole.material_override = _mat(Color(0.18, 0.18, 0.2))
			pole.position = Vector3(0, 2.6, 0)
			light.add_child(pole)
			for li in 3:
				var bulb := MeshInstance3D.new()
				var bs := SphereMesh.new()
				bs.radius = 0.22
				bs.height = 0.44
				bulb.mesh = bs
				var c: Color = [Color(0.9, 0.15, 0.12), Color(0.95, 0.75, 0.1), Color(0.2, 0.85, 0.35)][li]
				var bm := StandardMaterial3D.new()
				bm.albedo_color = c
				bm.emission_enabled = true
				bm.emission = c
				bm.emission_energy_multiplier = 1.8 if li == 0 else 0.15
				bulb.material_override = bm
				bulb.position = Vector3(0, 4.6 - li * 0.5, 0.16)
				light.add_child(bulb)

# ---------------------------------------------------------------- sidewalks
func _build_sidewalks(root: Node3D, id: String, info: Dictionary, _rng: RandomNumberGenerator) -> void:
	var pal: Dictionary = info["palette"]
	# Pavement gets the coarse mottle: slabs should read as slabs, not as one
	# continuous ribbon of colour.
	var walk := StandardMaterial3D.new()
	walk.albedo_color = pal["wall"].lightened(0.28)
	walk.roughness = 0.9
	var mottle := _surface("mottle")
	if mottle != null:
		walk.albedo_texture = mottle
		walk.uv1_triplanar = true
		walk.uv1_triplanar_sharpness = 8.0
		walk.uv1_scale = Vector3.ONE * 0.18
		walk.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var sw := Node3D.new()
	sw.name = "Sidewalks"
	root.add_child(sw)
	for i in [-1, 1]:
		for side in [-1, 1]:
			var b := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(146, 0.22, SIDEWALK_W)
			b.mesh = bm
			b.material_override = walk
			b.position = Vector3(0, 0.11, i * BLOCK + side * (ROAD_W * 0.5 + SIDEWALK_W * 0.5))
			sw.add_child(b)
			var v := MeshInstance3D.new()
			var vm := BoxMesh.new()
			vm.size = Vector3(SIDEWALK_W, 0.22, 146)
			v.mesh = vm
			v.material_override = walk
			v.position = Vector3(i * BLOCK + side * (ROAD_W * 0.5 + SIDEWALK_W * 0.5), 0.11, 0)
			sw.add_child(v)

# ---------------------------------------------------------------- buildings
func _build_buildings(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var pal: Dictionary = info["palette"]
	var g: Array = info["grid"]
	# District identity comes from geometry silhouette, not just colour:
	# Ash Row = low walk-ups, Vesper = towers, Iron Yard = sheds/containers,
	# Cinder Line = long foundry blocks, Neon Mile = mixed with signage,
	# Guttermarket = dense low stalls with awnings.
	var hm: Array = info["height"]
	var density: float = info["density"]
	var b_root := Node3D.new()
	b_root.name = "Buildings"
	root.add_child(b_root)

	var rows := 6
	var cols := 6
	for r in rows:
		for c in cols:
			if rng.randf() > density: continue
			# leave the road corridors clear
			var x := -62.0 + c * 24.0 + rng.randf_range(-3, 3)
			var z := -62.0 + r * 24.0 + rng.randf_range(-3, 3)
			if absf(absf(z) - BLOCK) < ROAD_W * 0.5 + 4.0: continue
			if absf(absf(x) - BLOCK) < ROAD_W * 0.5 + 4.0: continue
			var h := rng.randi_range(int(hm[0]), int(hm[1]))
			_add_building(b_root, Vector3(x, 0, z), h, pal, rng, int(info["tier"]), g)

	# perimeter ring: taller, frames the district
	for i in 24:
		var a := TAU * float(i) / 24.0
		var rad := 70.0
		var px := cos(a) * rad
		var pz := sin(a) * rad
		if rng.randf() > 0.72: continue
		_add_building(b_root, Vector3(px, 0, pz), rng.randi_range(int(hm[0]) + 1, int(hm[1]) + 3), pal, rng, int(info["tier"]), g)

## Each building is built with the rules the art-direction research insists on:
## silhouette variation before detail, windows on EVERY face (they used to be
## only on the +Z side, so every building read as flat cardboard from every
## other angle), a cornice and a recessed base for facade depth, and a vertical
## band that breaks up the monolith.
func _add_building(parent: Node3D, pos: Vector3, height_units: int, pal: Dictionary,
		rng: RandomNumberGenerator, tier: int, _grid: Array) -> void:
	var floor_h := 3.4
	var h := float(height_units) * floor_h
	# Silhouette variation: three footprint classes, not one
	var cls := rng.randi_range(0, 2)
	var w := rng.randf_range(9.0, 15.0)
	var d := rng.randf_range(9.0, 15.0)
	if cls == 1:
		w = rng.randf_range(6.0, 9.0); d = rng.randf_range(13.0, 19.0)   # slab tower
	elif cls == 2:
		w = rng.randf_range(13.0, 19.0); d = rng.randf_range(13.0, 19.0) # block

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var wall_col: Color = pal["wall"].darkened(rng.randf_range(0.0, 0.22))
	var wall_mat := _mat(wall_col, 0.72, 0.06)
	body.add_child(_box_mesh(Vector3(w, h, d), Vector3(0, h * 0.5, 0), wall_mat))
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h, d)
	shape.shape = bs
	shape.position = Vector3(0, h * 0.5, 0)
	body.add_child(shape)

	# Recessed ground floor: a darker plinth makes the base read as a base and
	# gives the eye a horizontal to sit on.
	body.add_child(_box_mesh(Vector3(w + 0.7, floor_h * 0.9, d + 0.7),
		Vector3(0, floor_h * 0.45, 0), _mat(wall_col.darkened(0.28), 0.9)))

	# Windows on all four faces.
	var win_mat := StandardMaterial3D.new()
	var lit := rng.randf() > 0.32
	var wc: Color = pal["accent"] if lit else Color(0.09, 0.10, 0.13)
	win_mat.albedo_color = wc
	win_mat.emission_enabled = lit
	win_mat.emission = wc
	win_mat.emission_energy_multiplier = rng.randf_range(1.2, 2.6) if lit else 0.0
	win_mat.roughness = 0.18
	win_mat.metallic = 0.35
	var floors := maxi(1, height_units)
	for f in floors:
		if f == 0: continue
		var y := f * floor_h + 1.9
		var per_w := maxi(2, int(w / 3.4))
		var per_d := maxi(2, int(d / 3.4))
		for wi in per_w:
			var x := -w * 0.5 + 1.7 + wi * (w - 3.4) / maxf(1.0, float(per_w - 1))
			if rng.randf() > 0.2:
				body.add_child(_quad(Vector2(1.1, 1.5), Vector3(x, y, d * 0.5 + 0.04), Vector3(0, 0, 1), win_mat))
				body.add_child(_quad(Vector2(1.1, 1.5), Vector3(x, y, -d * 0.5 - 0.04), Vector3(0, 0, -1), win_mat))
		for di in per_d:
			var z := -d * 0.5 + 1.7 + di * (d - 3.4) / maxf(1.0, float(per_d - 1))
			if rng.randf() > 0.2:
				body.add_child(_quad(Vector2(1.1, 1.5), Vector3(w * 0.5 + 0.04, y, z), Vector3(1, 0, 0), win_mat))
				body.add_child(_quad(Vector2(1.1, 1.5), Vector3(-w * 0.5 - 0.04, y, z), Vector3(-1, 0, 0), win_mat))

	# Vertical band breaks the flat monolith and catches raking light.
	if rng.randf() > 0.45:
		var band := _mat(pal["trim"].darkened(0.1), 0.6, 0.15)
		body.add_child(_box_mesh(Vector3(0.5, h * 0.94, d + 0.12),
			Vector3(w * 0.5 - 1.4, h * 0.5, 0), band))

	# Cornice: a deep overhang at the top, the single cheapest silhouette win.
	body.add_child(_box_mesh(Vector3(w + 1.1, 0.5, d + 1.1), Vector3(0, h + 0.22, 0),
		_mat(pal["trim"].darkened(0.12), 0.65, 0.1)))

	# Setback crown on taller buildings, so the skyline is not a row of slabs.
	if height_units >= 5 and rng.randf() > 0.35:
		var cw := w * rng.randf_range(0.4, 0.65)
		var cd := d * rng.randf_range(0.4, 0.65)
		var ch := rng.randf_range(2.0, 5.0)
		body.add_child(_box_mesh(Vector3(cw, ch, cd), Vector3(0, h + ch * 0.5 + 0.4, 0),
			_mat(wall_col.darkened(0.08), 0.7)))
		# tier 3 towers get a neon crown
		if tier >= 3:
			var neon := StandardMaterial3D.new()
			neon.albedo_color = pal["accent"]
			neon.emission_enabled = true
			neon.emission = pal["accent"]
			neon.emission_energy_multiplier = 3.4
			body.add_child(_box_mesh(Vector3(cw + 0.4, 0.2, cd + 0.4),
				Vector3(0, h + ch + 0.5, 0), neon))
	parent.add_child(body)

## A single-sided quad facing a given axis, for windows.
func _quad(size: Vector2, pos: Vector3, normal: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat
	mi.position = pos
	if normal.dot(Vector3(0, 0, 1)) < 0.5:
		mi.look_at_from_position(pos, pos + normal, Vector3.UP)
	parent_position_ok(mi)
	return mi

func parent_position_ok(_n: Node) -> void:
	pass

func _box_mesh(size: Vector3, offset: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = offset
	return mi

func _mat(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	m.roughness = roughness
	return m

# ---------------------------------------------------------------- street furniture
func _build_street_furniture(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var pal: Dictionary = info["palette"]
	var f_root := Node3D.new()
	f_root.name = "Furniture"
	root.add_child(f_root)
	var pole_mat := _mat(Color(0.16, 0.17, 0.19))
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.92, 0.72)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.86, 0.6)
	lamp_mat.emission_energy_multiplier = 2.2

	# Street lamps along both roads
	for i in range(-3, 4):
		if rng.randf() > 0.8: continue
		for side in [-1, 1]:
			var lamp := Node3D.new()
			lamp.position = Vector3(i * 18.0, 0, side * (BLOCK - ROAD_W * 0.5 - 1.6))
			f_root.add_child(lamp)
			var pole := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.12
			cyl.height = 6.4
			pole.mesh = cyl
			pole.material_override = pole_mat
			pole.position = Vector3(0, 3.2, 0)
			lamp.add_child(pole)
			var arm := _box_mesh(Vector3(1.5, 0.12, 0.12), Vector3(-side * 0.75, 6.3, 0), pole_mat)
			lamp.add_child(arm)
			var head := MeshInstance3D.new()
			var hm := SphereMesh.new()
			hm.radius = 0.3
			hm.height = 0.5
			head.mesh = hm
			head.material_override = lamp_mat
			head.position = Vector3(-side * 1.5, 6.15, 0)
			lamp.add_child(head)
			# Only every other lamp casts real light — mobile light budget.
			if i % 2 == 0:
				var l := OmniLight3D.new()
				l.light_color = Color(1.0, 0.88, 0.66)
				l.light_energy = 1.5
				l.omni_range = 13.0
				l.shadow_enabled = false
				l.position = Vector3(-side * 1.5, 5.9, 0)
				lamp.add_child(l)

	# Bins, bollards, and planters — cheap kitbash clutter using primitive shapes
	for i in 16:
		var x := rng.randf_range(-64, 64)
		var z := rng.randf_range(-64, 64)
		if absf(absf(z) - BLOCK) < 8.0 or absf(absf(x) - BLOCK) < 8.0: continue
		var prop := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.24
		cyl.height = 0.95
		prop.mesh = cyl
		prop.material_override = _mat(pal["trim"].darkened(0.35))
		prop.position = Vector3(x, 0.47, z)
		f_root.add_child(prop)

	# Bench clusters near intersections give the streets a human scale
	for i in 5:
		var bench := Node3D.new()
		var bx := rng.randf_range(-50, 50)
		var bz := rng.randf_range(-50, 50)
		if absf(absf(bz) - BLOCK) < 9.0: continue
		bench.position = Vector3(bx, 0, bz)
		f_root.add_child(bench)
		bench.add_child(_box_mesh(Vector3(1.9, 0.09, 0.5), Vector3(0, 0.46, 0), _mat(pal["trim"])))
		bench.add_child(_box_mesh(Vector3(1.9, 0.5, 0.08), Vector3(0, 0.68, -0.22), _mat(pal["trim"])))
		bench.add_child(_box_mesh(Vector3(0.09, 0.44, 0.44), Vector3(-0.85, 0.22, 0), _mat(Color(0.2, 0.2, 0.22))))
		bench.add_child(_box_mesh(Vector3(0.09, 0.44, 0.44), Vector3(0.85, 0.22, 0), _mat(Color(0.2, 0.2, 0.22))))

# ---------------------------------------------------------------- props
func _build_props(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var p_root := Node3D.new()
	p_root.name = "Props"
	root.add_child(p_root)
	var pal: Dictionary = info["palette"]
	# Crate / drum clusters: instance real Kenney models where available.
	var props := _kit_models("city-kit-commercial")
	for i in 12:
		if rng.randf() > 0.6: continue
		var x := rng.randf_range(-58, 58)
		var z := rng.randf_range(-58, 58)
		if absf(absf(z) - BLOCK) < 9.0 or absf(absf(x) - BLOCK) < 9.0: continue
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(rng.randf_range(0.7, 1.4), rng.randf_range(0.7, 1.2), rng.randf_range(0.7, 1.4))
		mi.mesh = b
		mi.material_override = _mat(pal["trim"].darkened(rng.randf_range(0.1, 0.4)))
		mi.position = Vector3(x, b.size.y * 0.5, z)
		mi.rotation.y = rng.randf_range(0, TAU)
		p_root.add_child(mi)

## Shared procedural surface tile. Returns null if the generator is missing,
## which degrades to the old flat-colour look instead of failing the build.
func _surface(kind: String) -> Texture2D:
	if _surface_cache.has(kind):
		return _surface_cache[kind]
	var sd = load("res://scripts/world/surface_detail.gd")
	var t: Texture2D = null
	if sd != null:
		t = sd.grain() if kind == "grain" else sd.mottle()
	_surface_cache[kind] = t
	return t

# ---------------------------------------------------------------- vehicles
func _build_parked_vehicles(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var v_root := Node3D.new()
	v_root.name = "ParkedVehicles"
	root.add_child(v_root)
	var kinds := ["sedan", "hatchback", "van", "taxi"]
	if int(info["tier"]) >= 2: kinds.append("muscle")
	if int(info["tier"]) >= 3: kinds.append("bike")
	var n := 5 + int(info["density"] * 4.0)
	for i in n:
		var kind: String = kinds[rng.randi() % kinds.size()]
		var model_name: String = Content.VEHICLE_TYPES[kind]["model"]
		var path := _vehicle_model_path(model_name)
		if path == "": continue
		var ps := load(path)
		if ps == null: continue
		var node = ps.instantiate()
		v_root.add_child(node)
		var side: float = 1.0 if rng.randf() > 0.5 else -1.0
		var along: int = [-1, 1][rng.randi() % 2]
		if rng.randf() > 0.5:
			node.position = Vector3(rng.randf_range(-60, 60), 0.05, along * BLOCK + side * (ROAD_W * 0.5 - 1.5))
			node.rotation.y = 0.0
		else:
			node.position = Vector3(along * BLOCK + side * (ROAD_W * 0.5 - 1.5), 0.05, rng.randf_range(-60, 60))
			node.rotation.y = PI * 0.5
		node.scale = Vector3.ONE * 1.25
		node.position.y = 0.33 * 1.25
		node.set_meta("vehicle_type", kind)
		node.set_meta("parked", true)

# ---------------------------------------------------------------- landmarks
func _build_landmarks(root: Node3D, id: String, info: Dictionary, rng: RandomNumberGenerator) -> void:
	var l_root := Node3D.new()
	l_root.name = "Landmarks"
	root.add_child(l_root)
	var pal: Dictionary = info["palette"]
	var landmarks: Array = info["landmarks"]
	var count := landmarks.size()
	for i in count:
		var lid: String = landmarks[i]
		var ang := TAU * float(i) / float(maxi(1, count)) + 0.4
		var pos := Vector3(cos(ang) * 30.0, 0, sin(ang) * 30.0)
		var node := Node3D.new()
		node.name = "LM_" + lid
		node.position = pos
		node.set_meta("landmark_id", lid)
		node.set_meta("interact", true)
		l_root.add_child(node)

		# Every landmark is a building with a lit sign band + an interaction portal
		var h := 8.0 + rng.randf() * 6.0
		if Content.INTERIORS.has(lid):
			node.set_meta("interior", lid)
			h = 6.0
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		node.add_child(body)
		body.add_child(_box_mesh(Vector3(13, h, 11), Vector3(0, h * 0.5, 0), _mat(pal["wall"].lightened(0.08))))
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(13, h, 11)
		shape.shape = bs
		shape.position = Vector3(0, h * 0.5, 0)
		body.add_child(shape)

		# sign band
		var sign_mat := StandardMaterial3D.new()
		sign_mat.albedo_color = pal["accent"]
		sign_mat.emission_enabled = true
		sign_mat.emission = pal["accent"]
		sign_mat.emission_energy_multiplier = 3.2
		body.add_child(_box_mesh(Vector3(11.5, 1.4, 0.25), Vector3(0, h - 1.2, 5.7), sign_mat))
		# awning
		body.add_child(_box_mesh(Vector3(12, 0.18, 2.6), Vector3(0, 3.3, 6.4), _mat(pal["trim"], 0.9)))
		# door glow quad
		var door_mat := StandardMaterial3D.new()
		door_mat.albedo_color = Color(1.0, 0.95, 0.85)
		door_mat.emission_enabled = true
		door_mat.emission = Color(1.0, 0.9, 0.7)
		door_mat.emission_energy_multiplier = 1.6
		body.add_child(_box_mesh(Vector3(2.4, 3.0, 0.2), Vector3(0, 1.5, 5.55), door_mat))
		# porch light
		var pl := OmniLight3D.new()
		pl.light_color = Color(1.0, 0.86, 0.62)
		pl.light_energy = 2.2
		pl.omni_range = 11.0
		pl.shadow_enabled = false
		pl.position = Vector3(0, 4.2, 7.0)
		node.add_child(pl)

func _kit_models(kit: String) -> Array:
	return []

func _vehicle_model_path(model_name: String) -> String:
	var p := "res://assets/models/vehicles/%s.glb" % model_name
	if ResourceLoader.exists(p): return p
	return ""

# ---------------------------------------------------------------- nav graphs
func _build_nav(root: Node3D, id: String) -> void:
	var nodes: Array[Vector3] = []
	for i in range(-3, 4):
		for side in [-1, 1]:
			for t in range(-3, 4):
				nodes.append(Vector3(t * 20.0, 0, i * BLOCK + side * (ROAD_W * 0.5 + SIDEWALK_W * 0.5)))
				nodes.append(Vector3(i * BLOCK + side * (ROAD_W * 0.5 + SIDEWALK_W * 0.5), 0, t * 20.0))
	nav_nodes[id] = nodes
	root.set_meta("nav_count", nodes.size())

func _build_drive_graph(root: Node3D, id: String) -> void:
	var nodes: Array[Vector3] = []
	for i in range(-4, 5):
		nodes.append(Vector3(i * 16.0, 0, BLOCK))
		nodes.append(Vector3(i * 16.0, 0, -BLOCK))
		nodes.append(Vector3(BLOCK, 0, i * 16.0))
		nodes.append(Vector3(-BLOCK, 0, i * 16.0))
	drive_graph[id] = nodes
	root.set_meta("drive_nodes", nodes.size())

# ---------------------------------------------------------------- instances
## instance_model("kaykit", "prop", scale, parent, pos, rot) — content-level model
## instancing used by interiors and detail passes. Returns the node or null.
func instance_model(_kit: String, prop: String, s: float, parent: Node, pos: Vector3, rot_y: float = 0.0) -> Node:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3.ONE * s
	mi.mesh = b
	mi.material_override = _mat(Color(0.6, 0.55, 0.5))
	mi.position = pos
	mi.rotation.y = rot_y
	mi.set_meta("prop", prop)
	parent.add_child(mi)
	return mi

# ---------------------------------------------------------------- spacing helper
func district_of(pos: Vector3) -> String:
	var best := "ash_row"
	var bestd = 1e9
	for id in Content.DISTRICTS:
		var c := Content.district_center(id)
		var d := Vector2(pos.x - c.x, pos.z - c.z).length()
		if d < bestd:
			bestd = d
			best = id
	return best
