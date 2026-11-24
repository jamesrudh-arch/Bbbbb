extends Node
## AUDIO — every sound in LEVERAGE is synthesized from scratch for this project
## (see tools/gen_audio.py + docs/AUDIO_DIRECTION.md): zero third-party samples,
## zero licensing obligations. Three buses: Music / SFX / Ambience.

var master_volume: float = 0.85
var music_volume: float = 0.55
var sfx_volume: float = 0.9

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _stingers: Array[AudioStreamPlayer] = []
var _pool: Array[AudioStreamPlayer3D] = []
var _ui: Array[AudioStreamPlayer] = []
var _world_started := false
var _music_state := ""

const MAX3D := 10
const MAX2D := 6

const SFX := {
	"footstep_concrete": "res://audio/sfx/step_concrete.wav",
	"footstep_gravel": "res://audio/sfx/step_gravel.wav",
	"punch_swing": "res://audio/sfx/punch_swing.wav",
	"punch_hit": "res://audio/sfx/punch_hit.wav",
	"kick_hit": "res://audio/sfx/kick_hit.wav",
	"heavy_hit": "res://audio/sfx/heavy_hit.wav",
	"dodge": "res://audio/sfx/dodge.wav",
	"block": "res://audio/sfx/block.wav",
	"stagger": "res://audio/sfx/stagger.wav",
	"down": "res://audio/sfx/down.wav",
	"gun_pistol": "res://audio/sfx/gun_pistol.wav",
	"gun_smg": "res://audio/sfx/gun_smg.wav",
	"gun_shotgun": "res://audio/sfx/gun_shotgun.wav",
	"reload": "res://audio/sfx/reload.wav",
	"door": "res://audio/sfx/door.wav",
	"engine_start": "res://audio/sfx/engine_start.wav",
	"engine_loop": "res://audio/sfx/engine_loop.wav",
	"horn": "res://audio/sfx/horn.wav",
	"pickup": "res://audio/sfx/pickup.wav",
	"money": "res://audio/sfx/money.wav",
	"explosion": "res://audio/sfx/explosion.wav",
	"click": "res://audio/ui/click.wav",
	"back": "res://audio/ui/back.wav",
	"confirm": "res://audio/ui/confirm.wav",
	"error": "res://audio/ui/error.wav",
}

func _ready() -> void:
	_music = _mk_music()
	_ambience = _mk_music()
	for i in 3:
		var s := AudioStreamPlayer.new()
		s.bus = "Music"
		add_child(s)
		_stingers.append(s)
	for i in MAX2D:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		_ui.append(s)
	for i in MAX3D:
		var s3 := AudioStreamPlayer3D.new()
		s3.bus = "SFX"
		s3.unit_size = 14.0
		s3.max_distance = 70.0
		add_child(s3)
		_pool.append(s3)
	apply_volume()

func _mk_music() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	add_child(p)
	return p

func _looped(path: String) -> AudioStream:
	if not ResourceLoader.exists(path): return null
	var st = load(path)
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st

# ---------------- volume ----------------
func apply_volume() -> void:
	var mb = AudioServer.get_bus_index("Music")
	var sb = AudioServer.get_bus_index("SFX")
	var ab = AudioServer.get_bus_index("Ambience")
	if mb >= 0: AudioServer.set_bus_volume_db(mb, linear_to_db(maxf(music_volume, 0.0001)))
	if sb >= 0: AudioServer.set_bus_volume_db(sb, linear_to_db(maxf(sfx_volume, 0.0001)))
	if ab >= 0: AudioServer.set_bus_volume_db(ab, linear_to_db(maxf(sfx_volume * 0.8, 0.0001)))
	var master = AudioServer.get_bus_index("Master")
	if master >= 0: AudioServer.set_bus_volume_db(master, linear_to_db(maxf(master_volume, 0.0001)))

# ---------------- world audio ----------------
func start_world_audio() -> void:
	if _world_started: return
	_world_started = true
	_music.stream = _looped("res://audio/music/explore.wav")
	_music.play()
	_ambience.stream = _looped("res://audio/ambience/city_bed.wav")
	_ambience.play()
	set_music_state("explore")

## Stop every player before the engine tears the audio server down. Music and
## ambience loop forever by design, so unless they are stopped they are still
## playing at exit and their playbacks are reported as leaked instances.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_stop_all()

func _stop_all() -> void:
	for p in [_music, _ambience]:
		if p != null and is_instance_valid(p):
			p.stop()
	for p in _stingers:
		if is_instance_valid(p):
			p.stop()
	for p in _ui:
		if is_instance_valid(p):
			p.stop()
	for p in _pool:
		if is_instance_valid(p):
			p.stop()

func stop_world_audio() -> void:
	_world_started = false
	_music.stop()
	_ambience.stop()

func set_music_state(state: String) -> void:
	if _music_state == state and _music.playing: return
	_music_state = state
	var path := "res://audio/music/explore.wav"
	if state == "tension" or state == "chase": path = "res://audio/music/tension.wav"
	var st = _looped(path)
	if st == null: return
	if _music.stream == st and _music.playing: return
	_music.stream = st
	_music.play()

func set_weather(w: String) -> void:
	# Rain ambience layers over the city bed.
	if w == "rain":
		var st = _looped("res://audio/ambience/rain.wav")
		if st != null and _ambience.stream != st:
			_ambience.stream = st
			_ambience.play()

# ---------------- playback ----------------
func _free_ui() -> AudioStreamPlayer:
	for s in _ui:
		if not s.playing: return s
	return _ui[0]

func play_ui(id: String, pitch: float = 1.0) -> void:
	var path: String = SFX.get(id, "")
	if path == "" or not ResourceLoader.exists(path): return
	var s := _free_ui()
	s.stream = load(path)
	s.pitch_scale = pitch
	s.volume_db = -6.0
	s.play()

func play_at(id: String, pos: Vector3, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var path: String = SFX.get(id, "")
	if path == "" or not ResourceLoader.exists(path): return
	var tree := get_tree()
	if tree == null or tree.current_scene == null: return
	# Take an idle player from the pool rather than allocating one. A node per
	# footstep is churn, and any playback still alive at teardown leaked an
	# AudioStreamPlaybackWAV (the pool existed but was never used).
	if _pool.is_empty(): return
	var p: AudioStreamPlayer3D = _pool[0]
	for c in _pool:
		if not c.playing:
			p = c
			break
	p.stream = load(path)
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.global_position = pos
	p.play()

func play_stinger(id: String) -> void:
	var map := {
		"alert": "res://audio/music/stinger_alert.wav",
		"mission": "res://audio/music/stinger_mission.wav",
		"complete": "res://audio/music/stinger_complete.wav",
	}
	var path: String = map.get(id, "")
	if path == "" or not ResourceLoader.exists(path): return
	var s := _stingers[0]
	for c in _stingers:
		if not c.playing: s = c; break
	s.stream = load(path)
	s.volume_db = -4.0
	s.play()
