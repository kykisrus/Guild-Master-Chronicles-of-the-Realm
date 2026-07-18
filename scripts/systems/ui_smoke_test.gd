extends SceneTree

## Run: godot --path . --headless -s res://scripts/systems/ui_smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== UI SMOKE TEST START ===")

	var err := change_scene_to_file("res://scenes/boot/intro_splash.tscn")
	assert(err == OK, "Failed to load intro splash")
	await process_frame
	await process_frame
	print("Splash OK")

	err = change_scene_to_file("res://scenes/menu/main_menu.tscn")
	assert(err == OK, "Failed to load main menu")
	await process_frame
	await process_frame
	print("Main menu OK")

	for scene_path in [
		"res://scenes/menu/load_menu.tscn",
		"res://scenes/menu/settings_menu.tscn",
		"res://scenes/menu/credits_menu.tscn",
	]:
		err = change_scene_to_file(scene_path)
		assert(err == OK, "Failed to load %s" % scene_path)
		await process_frame
		await process_frame
		print("Loaded ", scene_path)

	# Font / localization sanity
	var sample := tr("menu.new_game")
	assert(sample.length() > 0, "Localization empty")
	print("tr(menu.new_game)=", sample)

	# SaveLoad delete API
	var sl: Node = root.get_node("SaveLoad")
	assert(sl.SLOT_COUNT == 3, "Expected 3 slots")
	var status: int = sl.get_slot_status(1)
	print("Slot 1 status=", status)
	var del_err: String = sl.delete_save(99)
	assert(del_err != "", "Invalid slot should error")

	# Theme factory
	var theme: Theme = TinyThemeFactory.build()
	assert(theme != null, "Theme null")
	assert(theme.default_font != null, "Font missing in theme")
	var sample_ru := "Новая игра ОП"
	print("Theme font OK: ", theme.default_font)
	print("RU sample: ", sample_ru)

	print("=== UI SMOKE TEST PASS ===")
	quit(0)
