extends Node

const PATH := "user://settings.cfg"

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
	load_settings()
	apply()


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
	resolution = Vector2i(rw, rh)
	ui_scale = float(cfg.get_value("video", "ui_scale", 1.0))
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


func _apply_audio() -> void:
	var master_db := linear_to_db(clampf(master_volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		master_db if master_volume > 0.001 else -80.0
	)
	if MusicController != null and MusicController.has_method("set_music_volume"):
		MusicController.set_music_volume(music_volume)


func _apply_video() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	var tree := get_tree()
	if tree != null and tree.root != null:
		tree.root.content_scale_factor = clampf(ui_scale, 0.5, 2.0)
