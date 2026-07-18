extends Node

const PATH := "user://settings.cfg"

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1920, 1080),
]

const UI_SCALES: Array[float] = [1.0, 1.25, 1.5]

var show_tutorial: bool = true
var master_volume: float = 0.8
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false
var resolution: Vector2i = Vector2i(1280, 720)
var ui_scale: float = 1.0
var language: String = "ru"


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	# Defer video so the main Window exists and Steam Deck compositor is ready.
	call_deferred("apply")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	show_tutorial = bool(cfg.get_value("game", "show_tutorial", true))
	master_volume = float(cfg.get_value("audio", "master_volume", 0.8))
	music_volume = float(cfg.get_value("audio", "music_volume", 0.8))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", 0.8))
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	var rw := int(cfg.get_value("video", "resolution_w", 1280))
	var rh := int(cfg.get_value("video", "resolution_h", 720))
	resolution = _sanitize_resolution(Vector2i(rw, rh))
	ui_scale = _sanitize_ui_scale(float(cfg.get_value("video", "ui_scale", 1.0)))
	language = str(cfg.get_value("game", "language", "ru"))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "show_tutorial", show_tutorial)
	cfg.set_value("game", "language", language)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_w", resolution.x)
	cfg.set_value("video", "resolution_h", resolution.y)
	cfg.set_value("video", "ui_scale", ui_scale)
	cfg.save(PATH)


func reset_to_defaults() -> void:
	show_tutorial = true
	master_volume = 0.8
	music_volume = 0.8
	sfx_volume = 0.8
	fullscreen = false
	resolution = Vector2i(1280, 720)
	ui_scale = 1.0
	language = "ru"


func apply() -> void:
	_apply_audio()
	_apply_video()
	TranslationServer.set_locale(language)


func apply_audio_only() -> void:
	_apply_audio()


func _ensure_audio_buses() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, BUS_MASTER)


func _apply_audio() -> void:
	_set_bus_volume(BUS_MASTER, master_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, sfx_volume)
	if MusicController != null and MusicController.has_method("set_music_bus"):
		MusicController.set_music_bus(BUS_MUSIC)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(v) if v > 0.001 else -80.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)


func _apply_video() -> void:
	var win := get_window()
	if win == null:
		return

	ui_scale = _sanitize_ui_scale(ui_scale)
	resolution = _sanitize_resolution(resolution)
	win.content_scale_factor = ui_scale

	if fullscreen:
		# Borderless fullscreen uses the current screen; resolution list applies to windowed mode.
		if win.mode != Window.MODE_FULLSCREEN and win.mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
			win.mode = Window.MODE_FULLSCREEN
		return

	# Leave fullscreen / maximized first, then resize on the next frame.
	if win.mode != Window.MODE_WINDOWED:
		win.mode = Window.MODE_WINDOWED
	call_deferred("_apply_windowed_resolution")


func _apply_windowed_resolution() -> void:
	if fullscreen:
		return
	var win := get_window()
	if win == null:
		return
	win.mode = Window.MODE_WINDOWED
	win.size = resolution
	_center_window(win)
	# Some compositors ignore the first resize right after leaving fullscreen.
	await get_tree().process_frame
	if fullscreen:
		return
	win = get_window()
	if win == null:
		return
	if win.size != resolution:
		win.size = resolution
		_center_window(win)


func _center_window(win: Window) -> void:
	var screen := win.current_screen
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var target := resolution
	var pos := usable.position + Vector2i(
		maxi((usable.size.x - target.x) / 2, 0),
		maxi((usable.size.y - target.y) / 2, 0)
	)
	win.position = pos


func _sanitize_resolution(value: Vector2i) -> Vector2i:
	for res in RESOLUTIONS:
		if res == value:
			return value
	return RESOLUTIONS[0]


func _sanitize_ui_scale(value: float) -> float:
	for s in UI_SCALES:
		if is_equal_approx(s, value):
			return s
	return UI_SCALES[0]
