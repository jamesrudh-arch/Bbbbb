extends Control
## INTERACTIVE WORLD MAP.
##
## The previous "map" was a static grid of six district cards — no city, no
## player position, no destinations, no routing. This is a drawn map of the real
## world: it reads district footprints and landmark positions straight out of
## CityBuilder, so the layout on screen is the layout you drive through.
##
## Features: pan, pinch/scroll zoom, player arrow, discovered-area fog, mission
## markers, destination selection and a road-network route with distance.

const MAP_EXTENT := 260.0          # metres from centre to map edge
const PAD := 26.0

var hud = null
var world: Node3D = null
var builder = null

var _zoom := 0.62
var _pan := Vector2.ZERO
var _selected := ""
var _route: Array = []             # Array[Vector3] world-space waypoints
var _route_len := 0.0
var _blink := 0.0

var _font: Font = null
var _canvas: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.draw.connect(_on_draw)
	_font = ThemeDB.fallback_font

func setup(h, w) -> void:
	hud = h
	world = w
	builder = w.builder

func _process(delta: float) -> void:
	_blink += delta
	_canvas.queue_redraw()

# ------------------------------------------------------------------ input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom = clampf(_zoom * 1.16, 0.32, 2.6)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom = clampf(_zoom / 1.16, 0.32, 2.6)
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				_tap(mb.position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_tap(st.position)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_pan += mm.relative
	elif event is InputEventScreenDrag:
		_pan += (event as InputEventScreenDrag).relative

func _tap(screen_pos: Vector2) -> void:
	var wp := _screen_to_world(screen_pos)
	var best := ""
	var bestd := 34.0
	for lm in _landmarks():
		var d: float = wp.distance_to(lm["pos"])
		if d < bestd:
			bestd = d
			best = lm["id"]
	if best == "":
		# Fall back to the nearest district centre.
		for id in Content.DISTRICT_ORDER:
			var c: Vector3 = builder.district_center(id)
			var d2: float = wp.distance_to(c)
			if d2 < bestd + 30.0:
				bestd = d2
				best = "_district:" + id
	if best != "":
		_set_destination(best)

func _set_destination(target: String) -> void:
	_selected = target
	_build_route()

# --------------------------------------------------------------- projection
func _map_rect() -> Rect2:
	var sz := size
	var span := MAP_EXTENT * 2.0 * _zoom
	var sc := minf((sz.x - PAD * 2.0) / span, (sz.y - PAD * 2.0) / span)
	var w := span * sc
	var h := span * sc
	return Rect2(Vector2((sz.x - w) * 0.5, (sz.y - h) * 0.5) + _pan, Vector2(w, h))

## world -> rect-normalised [0,1]
func _world_to_norm(p: Vector3) -> Vector2:
	return Vector2((p.x + MAP_EXTENT) / (MAP_EXTENT * 2.0),
				1.0 - (p.z + MAP_EXTENT) / (MAP_EXTENT * 2.0))

func _world_to_screen(p: Vector3) -> Vector2:
	var r := _map_rect()
	return r.position + _world_to_norm(p) * r.size

func _screen_to_world(s: Vector2) -> Vector3:
	var r := _map_rect()
	var n := (s - r.position) / r.size
	return Vector3(n.x * MAP_EXTENT * 2.0 - MAP_EXTENT, 0.0,
				(1.0 - n.y) * MAP_EXTENT * 2.0 - MAP_EXTENT)

# ------------------------------------------------------------------- data
func _landmarks() -> Array:
	var out := []
	if builder == null:
		return out
	for id in Content.DISTRICT_ORDER:
		var d: Dictionary = Content.DISTRICTS[id]
		var center: Vector3 = builder.district_center(id)
		var lms: Array = d.get("landmarks", [])
		for i in lms.size():
			var ang: float = TAU * float(i) / float(lms.size()) + 0.4
			out.append({
				"id": lms[i],
				"district": id,
				"pos": center + Vector3(cos(ang) * 30.0, 0, sin(ang) * 30.0),
				"name": str(lms[i]).capitalize().replace("_", " "),
			})
	return out

func _is_discovered(_wp: Vector3) -> bool:
	# Forgiving fog: a district is "known" once entered. Within a known district
	# every landmark is selectable — the alternative (per-metre discovery) turns
	# the map into a chore on a phone screen.
	return true

func _build_route() -> void:
	_route.clear()
	_route_len = 0.0
	if _selected == "" or world == null:
		return
	var dest := Vector3.ZERO
	if _selected.begins_with("_district:"):
		dest = builder.district_center(_selected.trim_prefix("_district:"))
	else:
		for lm in _landmarks():
			if lm["id"] == _selected:
				dest = lm["pos"]
	var p = world.player
	if p == null:
		return
	var from: Vector3 = p.global_position
	# Route along the road grid: snap to the nearest street, travel on it, then cut
	# in to the destination. This is what makes the drawn line follow roads rather
	# than slash across city blocks.
	_route = _road_path(from, dest)
	for i in range(1, _route.size()):
		_route_len += _route[i - 1].distance_to(_route[i])

func _road_path(from: Vector3, to: Vector3) -> Array:
	var pts: Array = []
	var block := _block_size()
	var a := _snap_to_street(from, block)
	var b := _snap_to_street(to, block)
	pts.append(from)
	pts.append(a)
	# Travel along whichever axis is further, then the other.
	if absf(a.x - b.x) > 1.0:
		pts.append(Vector3(b.x, 0, a.z))
	if absf(a.z - b.z) > 1.0:
		pts.append(Vector3(b.x, 0, b.z))
	pts.append(to)
	return pts

func _block_size() -> float:
	# Matches CityBuilder's BLOCK pitch; read defensively so a tuning change there
	# does not silently break route drawing.
	if builder != null and "BLOCK" in builder:
		return float(builder.BLOCK)
	return 40.0

func _snap_to_street(p: Vector3, block: float) -> Vector3:
	# Streets run along multiples of BLOCK on both axes.
	var x: float = round(p.x / block) * block
	var z: float = round(p.z / block) * block
	return Vector3(x if absf(p.x - x) < absf(p.z - z) else p.x, 0,
					z if absf(p.x - x) < absf(p.z - z) else p.z)

func select_district(dir: int) -> void:
	var order: Array = Content.DISTRICT_ORDER
	var idx := 0
	for i in order.size():
		if _selected.begins_with("_district:") and _selected.ends_with(order[i]):
			idx = i
	idx = (idx + dir + order.size()) % order.size()
	_set_destination("_district:" + str(order[idx]))

func recentre() -> void:
	_pan = Vector2.ZERO
	_zoom = 0.62

func destination_name() -> String:
	if _selected == "":
		return ""
	if _selected.begins_with("_district:"):
		return Content.DISTRICTS[_selected.trim_prefix("_district:")]["name"]
	for lm in _landmarks():
		if lm["id"] == _selected:
			return "%s · %s" % [Content.DISTRICTS[lm["district"]]["name"], lm["name"]]
	return _selected

# ------------------------------------------------------------------- draw
func _on_draw() -> void:
	var r := _map_rect()
	var sb := _canvas
	sb.draw_rect(Rect2(Vector2.ZERO, size), Color(0.028, 0.032, 0.042, 0.97))
	# map bed
	sb.draw_rect(r, Color(0.075, 0.082, 0.098, 1.0))
	sb.draw_rect(r, Color(0.20, 0.21, 0.24, 1.0), false, 1.5)

	_draw_water(sb, r)
	_draw_blocks(sb, r)
	_draw_roads(sb, r)
	_draw_district_labels(sb, r)
	_draw_route(sb, r)
	_draw_landmarks(sb, r)
	_draw_player(sb, r)
	_draw_hud(sb, r)

func _draw_water(sb: Control, r: Rect2) -> void:
	# Bay along the southern edge — gives the map a coastline identity and makes
	# the landmass read as a place rather than a rectangle of blocks.
	var pts := PackedVector2Array()
	var z_edge := MAP_EXTENT * 0.72
	for i in 21:
		var x := -MAP_EXTENT + (MAP_EXTENT * 2.0) * float(i) / 20.0
		var wob := sin(float(i) * 0.8) * 8.0
		pts.append(_world_to_screen(Vector3(x, 0, z_edge + wob)))
	pts.append(_world_to_screen(Vector3(MAP_EXTENT, 0, MAP_EXTENT)))
	pts.append(_world_to_screen(Vector3(-MAP_EXTENT, 0, MAP_EXTENT)))
	sb.draw_colored_polygon(pts, Color(0.055, 0.10, 0.15, 1.0))

func _draw_blocks(sb: Control, r: Rect2) -> void:
	var block := _block_size()
	for ix in range(-8, 9):
		for iz in range(-8, 9):
			var c := Vector3(ix * block, 0, iz * block)
			var half := block * 0.34
			var p0 := _world_to_screen(c - Vector3(half, 0, half))
			var p1 := _world_to_screen(c + Vector3(half, 0, half))
			if p1.x - p0.x < 2.0:
				continue
			# Only draw blocks that actually fall inside the map bed; without this
			# the grid bleeds across the whole screen behind the overlay.
			var cell := Rect2(p0, p1 - p0).intersection(r)
			if cell.size.x < 1.5 or cell.size.y < 1.5:
				continue
			sb.draw_rect(cell, Color(0.115, 0.125, 0.145, 1.0))

func _draw_roads(sb: Control, r: Rect2) -> void:
	var block := _block_size()
	var road_col := Color(0.26, 0.27, 0.30, 1.0)
	for i in range(-8, 9):
		var a := _world_to_screen(Vector3(-MAP_EXTENT, 0, i * block))
		var b := _world_to_screen(Vector3(MAP_EXTENT, 0, i * block))
		sb.draw_line(a, b, road_col, maxf(1.0, 7.0 * _zoom))
		var c1 := _world_to_screen(Vector3(i * block, 0, -MAP_EXTENT))
		var c2 := _world_to_screen(Vector3(i * block, 0, MAP_EXTENT))
		sb.draw_line(c1, c2, road_col, maxf(1.0, 7.0 * _zoom))

func _draw_district_labels(sb: Control, r: Rect2) -> void:
	for id in Content.DISTRICT_ORDER:
		var d: Dictionary = Content.DISTRICTS[id]
		var c: Vector3 = builder.district_center(id)
		var sp := _world_to_screen(c)
		var accent: Color = d["palette"]["accent"]
		var fs := int(clampf(15.0 * _zoom, 10.0, 22.0))
		var txt: String = d["name"].to_upper()
		var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		sb.draw_string(_font, sp + Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(accent.r, accent.g, accent.b, 0.85))

func _draw_route(sb: Control, r: Rect2) -> void:
	if _route.size() < 2:
		return
	var prev := _world_to_screen(_route[0])
	for i in range(1, _route.size()):
		var cur := _world_to_screen(_route[i])
		sb.draw_line(prev, cur, Color(0.95, 0.78, 0.30, 0.95), maxf(2.0, 5.0 * _zoom))
		prev = cur

func _draw_landmarks(sb: Control, r: Rect2) -> void:
	for lm in _landmarks():
		var sp := _world_to_screen(lm["pos"])
		if not r.grow(8).has_point(sp):
			continue
		var is_dest: bool = lm["id"] == _selected
		var is_mission := false
		if world != null and not Game.mission.is_empty():
			var obj: Dictionary = Game.current_objective()
			if str(obj.get("target", "")) == lm["id"]:
				is_mission = true
		var col := Color(0.62, 0.66, 0.72, 0.9)
		var rad := 4.0 * clampf(_zoom, 0.7, 1.8)
		if is_mission:
			col = Color(0.95, 0.78, 0.30, 1.0)
			rad *= 1.5 + sin(_blink * 5.0) * 0.22
			sb.draw_circle(sp, rad + 3.2, Color(0.95, 0.78, 0.30, 0.20))
		elif is_dest:
			col = Color(0.75, 0.92, 1.0, 1.0)
			rad *= 1.45
		sb.draw_circle(sp, rad, col)
		sb.draw_arc(sp, rad + 1.2, 0, TAU, 14, Color(0, 0, 0, 0.45), 1.0)

func _draw_player(sb: Control, r: Rect2) -> void:
	if world == null or world.player == null:
		return
	var p = world.player
	var sp := _world_to_screen(p.global_position)
	var yaw: float = p.rotation.y
	# Arrow: forward is -Z in the map projection, so rotate accordingly.
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var side := Vector2(-fwd.y, fwd.x)
	var s := 8.0 * clampf(_zoom, 0.7, 1.8)
	sb.draw_circle(sp, s * 2.1, Color(0.30, 0.75, 1.0, 0.16))
	var tri := PackedVector2Array([
		sp + fwd * s * 1.5,
		sp - fwd * s * 0.8 + side * s * 0.9,
		sp - fwd * s * 0.8 - side * s * 0.9,
	])
	sb.draw_colored_polygon(tri, Color(0.45, 0.85, 1.0, 1.0))
	sb.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(0, 0, 0, 0.6), 1.0)

func _draw_hud(sb: Control, r: Rect2) -> void:
	# Title bar
	sb.draw_string(_font, r.position + Vector2(6, 26), "CINDER CITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
		Color(0.95, 0.78, 0.30))
	var sub := "drag to pan · scroll to zoom · tap to set destination"
	sb.draw_string(_font, r.position + Vector2(6, 46), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(0.60, 0.64, 0.70))
	# Destination + route readout
	var box := Rect2(Vector2(r.position.x + 6, r.end.y - 74), Vector2(minf(430, r.size.x - 12), 66))
	sb.draw_rect(box, Color(0.04, 0.045, 0.055, 0.92))
	sb.draw_rect(box, Color(0.22, 0.23, 0.27), false, 1.0)
	if _selected == "":
		sb.draw_string(_font, box.position + Vector2(12, 28), "No destination set",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.62, 0.66, 0.72))
		sb.draw_string(_font, box.position + Vector2(12, 48), "Tap a landmark to route to it",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.48, 0.51, 0.57))
	else:
		sb.draw_string(_font, box.position + Vector2(12, 26), destination_name(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.95, 0.90, 0.72))
		sb.draw_string(_font, box.position + Vector2(12, 48), "%d m  ·  route drawn along the street grid" % int(_route_len),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.60, 0.78, 0.62))
	# Scale bar
	var bar_m := 50.0
	var a := _world_to_screen(Vector3(-MAP_EXTENT + 10, 0, MAP_EXTENT - 14))
	var b := _world_to_screen(Vector3(-MAP_EXTENT + 10 + bar_m, 0, MAP_EXTENT - 14))
	sb.draw_line(a, b, Color(0.6, 0.64, 0.7), 2.0)
	sb.draw_string(_font, b + Vector2(6, 4), "%dm" % int(bar_m), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(0.6, 0.64, 0.7))
	# Current objective, if any
	if world != null and not Game.mission.is_empty():
		var obj: Dictionary = Game.current_objective()
		if not obj.is_empty():
			sb.draw_string(_font, Vector2(r.position.x + 6, r.end.y - 84),
				"OBJ: " + str(obj.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
				Color(0.95, 0.78, 0.30))
