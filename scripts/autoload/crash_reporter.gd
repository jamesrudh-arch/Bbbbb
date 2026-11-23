extends Node
## CRASH REPORTER — local, private diagnostics with an optional remote sink.
##
## Records unhandled errors, warnings and session state to a rolling log so a
## failure on a real iPhone can be diagnosed. No remote endpoint is configured by
## default: nothing leaves the device unless one is set here.

const LOG_PATH := "user://crash.log"
const MAX_BYTES := 262144
# Set this to an HTTPS collector URL to enable remote reporting.
const REMOTE_ENDPOINT := ""

var _session_start := 0
var _events: Array = []
var _http: HTTPRequest

func _ready() -> void:
	_session_start = Time.get_ticks_msec()
	_write("session start  engine=%s  os=%s" % [
		Engine.get_version_info().get("string", "?"), OS.get_name()])
	if REMOTE_ENDPOINT != "":
		_http = HTTPRequest.new()
		add_child(_http)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_write("session end after %.1fs" % ((Time.get_ticks_msec() - _session_start) / 1000.0))

## Call from anywhere for a diagnostic breadcrumb; cheap enough to fire often.
func event(tag: String, detail: String = "") -> void:
	_events.append("%s %s" % [tag, detail])
	if _events.size() > 40:
		_events.pop_front()
	_write("%s %s" % [tag, detail])

func report_error(message: String, context: String = "") -> void:
	_write("ERROR %s | %s" % [context, message])
	_write("  recent: " + " -> ".join(_events))
	_flush_remote("error", message, context)

func _flush_remote(kind: String, message: String, context: String) -> void:
	if REMOTE_ENDPOINT == "" or _http == null:
		return
	var body := JSON.stringify({
		"kind": kind, "message": message, "context": context,
		"os": OS.get_name(), "version": Engine.get_version_info().get("string", ""),
		"events": _events,
	})
	_http.request(REMOTE_ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _write(line: String) -> void:
	var stamp := Time.get_datetime_string_from_system(false, true)
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	if f.get_length() > MAX_BYTES:
		f.close()
		_rotate()
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if f == null:
			return
	f.store_line("%s  %s" % [stamp, line])
	f.close()

func _rotate() -> void:
	var old := FileAccess.open(LOG_PATH, FileAccess.READ)
	if old == null:
		return
	var keep := old.get_buffer(mini(int(old.get_length()), 60000))
	old.close()
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f != null:
		f.store_buffer(keep)
		f.close()

func read_log() -> String:
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	return f.get_as_text() if f != null else ""
