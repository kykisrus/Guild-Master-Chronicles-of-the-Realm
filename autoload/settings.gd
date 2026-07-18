extends Node

const PATH := "user://settings.cfg"

var show_tutorial: bool = true
var master_volume: float = 0.8
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	show_tutorial = bool(cfg.get_value("game", "show_tutorial", true))
	master_volume = float(cfg.get_value("audio", "master_volume", 0.8))
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "show_tutorial", show_tutorial)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func apply() -> void:
	var db := linear_to_db(clampf(master_volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db if master_volume > 0.001 else -80.0)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
