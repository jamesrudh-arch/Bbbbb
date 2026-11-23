extends Control
## THE PHONE — a device, not a menu.
##
## Previous version listed 16 contacts and dumped a bio when tapped. This one has
## real state: contacts with call/message history, an incoming-call screen that
## rings, answer/decline, conversation playback line by line, message threads with
## unread badges, and story hooks (a call can set a flag or unlock a mission).
##
## Call scheduling lives in PhoneSystem (scripts/systems/phone_system.gd); this node
## is presentation + input.

const CALL_SCREEN := 0
const HOME := 1
const THREADS := 2
const CONVO := 3

var hud = null
var world: Node3D = null

var _screen := HOME
var _contact := ""          # open thread / call
var _line_idx := 0
var _lines: Array = []
var _ring_time := 0.0
var _is_ringing := false
var _call_is_outgoing := false

var _root: VBoxContainer
var _ring_overlay: Control
var _bed: ColorRect
var _font: Font
var _blink := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_bed = ColorRect.new()
	_bed.color = Color(0.055, 0.062, 0.075, 0.985)
	_bed.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bed.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bed)
	_root = VBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.custom_minimum_size = Vector2(400, 600)
	_root.position = Vector2(-200, -300)
	add_child(_root)

func setup(h, w) -> void:
	hud = h
	world = w

func _process(delta: float) -> void:
	if _is_ringing:
		_ring_time += delta
		_blink += delta
		_ring_overlay.queue_redraw()

# ------------------------------------------------------------------ ringing
## Called by PhoneSystem when a scripted call arrives.
func ring(call_id: String) -> void:
	var c: Dictionary = Content.CALLS[call_id]
	_is_ringing = true
	_ring_time = 0.0
	_ring_overlay = Control.new()
	_ring_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_ring_overlay)
	_ring_overlay.draw.connect(func(): _draw_ring(_ring_overlay, call_id))
	Audio.play_stinger("phone")
	Game.current_call = call_id

func answer() -> void:
	if not _is_ringing:
		return
	_is_ringing = false
	var call_id: String = Game.current_call
	var c: Dictionary = Content.CALLS.get(call_id, {})
	if c.is_empty():
		_close_ring()
		return
	Audio.stop_stinger()
	if c.get("flag", "") != "":
		Game.set_flag(c["flag"])
	Game.call_log.append({"from": c.get("from", ""), "id": call_id, "answered": true, "at": Game.hour})
	_close_ring()
	_play_conversation(c.get("lines", []), str(c.get("title", "")))

func decline() -> void:
	if not _is_ringing:
		return
	_is_ringing = false
	var call_id: String = Game.current_call
	var c: Dictionary = Content.CALLS.get(call_id, {})
	Audio.stop_stinger()
	Game.call_log.append({"from": c.get("from", ""), "id": call_id, "answered": false, "at": Game.hour})
	Game.missed_calls.append(call_id)
	_close_ring()
	if hud != null:
		hud.show_toast("Missed call · " + str(c.get("title", "")))

func _close_ring() -> void:
	_is_ringing = false
	Game.current_call = ""
	if _ring_overlay != null:
		_ring_overlay.queue_free()
		_ring_overlay = null

func _draw_ring(cv: Control, call_id: String) -> void:
	var c: Dictionary = Content.CALLS.get(call_id, {})
	var sz := cv.size
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.025, 0.035, 0.92))
	var card_w := 380.0
	var card_h := 300.0
	var x := (sz.x - card_w) * 0.5
	var y := (sz.y - card_h) * 0.5
	var card := Rect2(x, y, card_w, card_h)
	cv.draw_rect(card, Color(0.06, 0.07, 0.085, 1.0))
	cv.draw_rect(card, Color(0.22, 0.24, 0.28), false, 1.5)
	# Pulsing avatar ring
	var cid: String = c.get("from", "")
	var col: Color = Content.CHARACTERS.get(cid, {}).get("color", Color(0.8, 0.8, 0.8))
	var cx := x + card_w * 0.5
	var cy := y + 108.0
	var pulse := 1.0 + sin(_blink * 4.2) * 0.06
	cv.draw_circle(Vector2(cx, cy), 52.0 * pulse, Color(col.r, col.g, col.b, 0.16))
	cv.draw_circle(Vector2(cx, cy), 40.0, Color(col.r, col.g, col.b, 0.9))
	cv.draw_circle(Vector2(cx, cy), 40.0, Color(0, 0, 0, 0.25), false, 2.0)
	var initials := ""
	for part in str(c.get("title", "?")).split(" "):
		if part.length() > 0: initials += part.substr(0, 1)
	cv.draw_string(_font, Vector2(cx - 14, cy + 8), initials.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0, 0, 0, 0.85))
	var dot := ".".repeat(int(_blink * 2.0) % 4)
	cv.draw_string(_font, Vector2(x + 24, y + 196), "INCOMING CALL" + dot,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.62, 0.72))
	cv.draw_string(_font, Vector2(x + 24, y + 224), str(c.get("title", "")),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.95, 0.93, 0.86))
	# buttons
	var by := y + card_h - 62
	var bw := 130.0
	_draw_btn(cv, Rect2(x + 40, by, bw, 46), "DECLINE", Color(0.55, 0.16, 0.16))
	_draw_btn(cv, Rect2(x + card_w - 40 - bw, by, bw, 46), "ANSWER", Color(0.16, 0.48, 0.28))

func _draw_btn(cv: Control, r: Rect2, label: String, col: Color) -> void:
	cv.draw_rect(r, col)
	cv.draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	cv.draw_string(_font, r.position + Vector2((r.size.x - w) * 0.5, r.size.y * 0.5 + 6),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.95, 0.92))

func _unhandled_input(event: InputEvent) -> void:
	if not _is_ringing:
		return
	if event is InputEventScreenTouch and event.pressed:
		var p: Vector2 = event.position
		var sz := size
		var card_w := 380.0
		var card_h := 300.0
		var x := (sz.x - card_w) * 0.5
		var y := (sz.y - card_h) * 0.5
		var by := y + card_h - 62
		if Rect2(x + 40, by, 130, 46).has_point(p):
			decline()
		elif Rect2(x + card_w - 170, by, 130, 46).has_point(p):
			answer()

# ------------------------------------------------------------------ home
func show_home() -> void:
	_screen = HOME
	_clear()
	_root.add_child(_hdr("LEVERAGE OS", "PHONE", Color(0.95, 0.78, 0.30)))
	_root.add_child(_sub("Emeka Obi · Ash Row"))
	_root.add_child(_sep())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_btn("CALLS", func(): show_contacts(true)))
	row.add_child(_btn("MESSAGES", func(): show_contacts(false)))
	row.add_child(_btn("RADIO", func(): _cycle_radio()))
	_root.add_child(row)
	_root.add_child(_sep())
	var recent: Array = Game.call_log.slice(maxi(0, Game.call_log.size() - 3))
	if not recent.is_empty():
		_root.add_child(_sub("RECENT"))
		for entry in recent:
			var cname: String = Content.CHARACTERS.get(entry.get("from", ""), {}).get("name", "Unknown")
			var state := "answered" if entry.get("answered", false) else "missed"
			_root.add_child(_sub("· %s — %s" % [cname, state]))
	var unread := _unread_total()
	if unread > 0:
		_root.add_child(_sub("%d unread message%s" % [unread, "" if unread == 1 else "s"]))
	_root.add_child(_spacer())
	_root.add_child(_btn("PUT AWAY", func(): _close()))

func show_contacts(for_calls: bool) -> void:
	_screen = CALL_SCREEN if for_calls else THREADS
	_clear()
	_root.add_child(_hdr("", "CONTACTS" if for_calls else "MESSAGES", Color(0.95, 0.78, 0.30)))
	_root.add_child(_sub("Tap to call" if for_calls else "Tap to read"))
	_root.add_child(_sep())
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 420)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	_root.add_child(sc)
	for cid in Content.CHARACTERS:
		var c: Dictionary = Content.CHARACTERS[cid]
		var label: String = str(c["name"])
		var unread := _unread_for(cid)
		if not for_calls and unread > 0:
			label += "  (%d)" % unread
		var b := _btn(label, func(): _open_contact(cid, for_calls))
		if not for_calls and unread > 0:
			b.modulate = Color(1.0, 0.95, 0.72)
		list.add_child(b)
	_root.add_child(_sep())
	_root.add_child(_btn("BACK", func(): show_home()))

func _open_contact(cid: String, for_calls: bool) -> void:
	_contact = cid
	if for_calls:
		var call_id := _call_for(cid)
		if call_id != "":
			_outgoing(call_id)
		else:
			if hud != null: hud.show_toast(str(Content.CHARACTERS[cid]["name"]) + " isn't picking up")
	else:
		Game.read_messages(cid)
		show_thread(cid)

func _call_for(cid: String) -> String:
	for cid2 in Content.CALLS:
		if Content.CALLS[cid2]["from"] == cid:
			return cid2
	return ""

func _outgoing(call_id: String) -> void:
	var c: Dictionary = Content.CALLS[call_id]
	Game.call_log.append({"from": c.get("from", ""), "id": call_id, "answered": true, "at": Game.hour})
	if c.get("flag", "") != "":
		Game.set_flag(c["flag"])
	_play_conversation(c.get("lines", []), str(c.get("title", "")))

func _play_conversation(lines: Array, title: String) -> void:
	_close_ring()
	_screen = CONVO
	_lines = lines
	_line_idx = 0
	_clear()
	_root.add_child(_hdr("CALL", title, Color(0.45, 0.85, 1.0)))
	_root.add_child(_sep())
	for i in _line_idx + 1:
		if i >= _lines.size(): break
		var pair: Array = _lines[i]
		var who: String = str(pair[0])
		var text: String = str(pair[1])
		var nm: String = Content.CHARACTERS.get(who, {}).get("name", who.capitalize())
		var lbl := _sub(("%s: %s" % [nm, text]) if who != "emeka" else ("You: " + text))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(360, 0)
		_root.add_child(lbl)
	_root.add_child(_spacer())
	var more := _line_idx + 1 < _lines.size()
	_root.add_child(_btn("CONTINUE" if more else "HANG UP", func():
		if more:
			_line_idx += 1
			_play_conversation(_lines, title)
		else:
			show_home()
	))

func show_thread(cid: String) -> void:
	_screen = THREADS
	_clear()
	var c: Dictionary = Content.CHARACTERS.get(cid, {})
	_root.add_child(_hdr("THREAD", str(c.get("name", cid)), Color(0.55, 0.85, 0.65)))
	_root.add_child(_sep())
	var list: Array = Game.messages.get(cid, [])
	if list.is_empty():
		_root.add_child(_sub("No messages."))
	else:
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(0, 420)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(box)
		_root.add_child(sc)
		for m in list:
			var lbl := _sub("· " + str(m.get("text", "")))
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.custom_minimum_size = Vector2(360, 0)
			box.add_child(lbl)
	_root.add_child(_spacer())
	_root.add_child(_btn("BACK", func(): show_contacts(false)))

func _unread_for(cid: String) -> int:
	var n := 0
	for m in Game.messages.get(cid, []):
		if not m.get("read", false): n += 1
	return n

func _unread_total() -> int:
	var n := 0
	for cid in Game.messages:
		n += _unread_for(cid)
	return n

func _cycle_radio() -> void:
	var stations: Array = Content.RADIO["stations"]
	var i := 0
	for k in stations.size():
		if stations[k]["id"] == Game.radio_station: i = k
	i = (i + 1) % stations.size()
	Game.radio_station = stations[i]["id"]
	var rep: Array = Content.RADIO["reports"]
	if not rep.is_empty() and Game.radio_station != "none":
		var r: Dictionary = rep[randi() % rep.size()]
		if hud != null: hud.show_dialogue(stations[i]["name"], r["title"] + " — " + r["text"])
	else:
		if hud != null: hud.show_dialogue(stations[i]["name"], stations[i]["desc"])

func _close() -> void:
	visible = false

# ------------------------------------------------------------------ widgets
func _clear() -> void:
	for ch in _root.get_children():
		_root.remove_child(ch)
		ch.queue_free()

func _hdr(top: String, title: String, col: Color) -> Control:
	var v := VBoxContainer.new()
	if top != "": v.add_child(_mk_label(top, 11, Color(0.55, 0.60, 0.68)))
	v.add_child(_mk_label(title, 24, col))
	return v

func _sub(t: String) -> Label:
	return _mk_label(t, 13, Color(0.66, 0.70, 0.76))

func _mk_label(t: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

func _sep() -> HSeparator:
	return HSeparator.new()

func _spacer() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 8)
	return c

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	b.custom_minimum_size = Vector2(0, 42)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(cb)
	return b
