extends SceneTree

## godot --path . --headless -s res://scripts/systems/settings_smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var s: Node = root.get_node("Settings")
	s.fullscreen = false
	s.resolution = Vector2i(1280, 800)
	s.ui_scale = 1.25
	s.master_volume = 0.5
	s.music_volume = 0.4
	s.sfx_volume = 0.3
	s.apply()
	await process_frame
	await process_frame
	var win: Window = root
	print("mode=", win.mode, " size=", win.size, " scale=", win.content_scale_factor)
	assert(AudioServer.get_bus_index("Music") >= 0, "Music bus missing")
	assert(AudioServer.get_bus_index("SFX") >= 0, "SFX bus missing")
	assert(is_equal_approx(win.content_scale_factor, 1.25), "UI scale not applied")
	s.resolution = Vector2i(1920, 1080)
	s.apply()
	await process_frame
	await process_frame
	s.save_settings()
	var cfg := ConfigFile.new()
	assert(cfg.load("user://settings.cfg") == OK, "settings.cfg missing")
	assert(int(cfg.get_value("video", "resolution_w")) == 1920)
	assert(int(cfg.get_value("video", "resolution_h")) == 1080)
	assert(is_equal_approx(float(cfg.get_value("video", "ui_scale")), 1.25))
	print("SETTINGS SMOKE PASS")
	quit(0)
