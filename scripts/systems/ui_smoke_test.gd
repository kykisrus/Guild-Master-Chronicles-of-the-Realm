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
		"res://scenes/ui/dialogue/dialogue_box.tscn",
		"res://scenes/intro/guildmaster_registration.tscn",
		"res://scenes/intro/guild_creation.tscn",
		"res://scenes/intro/intro_field.tscn",
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

	# Legacy settings theme still works
	var tiny_theme: Theme = TinyThemeFactory.build()
	assert(tiny_theme != null, "TinyTheme null")
	assert(tiny_theme.default_font != null, "Font missing in TinyTheme")
	print("TinyTheme font OK")

	# Tiny Swords bake + theme
	var baked: ImageTexture = TinySwordsUi.bake_seamless_panel(TinySwordsUi.PAPER_SPECIAL)
	assert(baked != null, "bake_seamless_panel returned null")
	assert(baked.get_width() >= 24, "baked panel too small")
	print("Bake OK: ", baked.get_width(), "x", baked.get_height())

	var swords_theme: Theme = TinySwordsThemeFactory.build()
	assert(swords_theme != null, "TinySwordsTheme null")
	assert(swords_theme.default_font != null, "Font missing in TinySwordsTheme")
	var panel_sb := swords_theme.get_stylebox("panel", "PanelContainer")
	assert(panel_sb is StyleBoxTexture, "Panel style should be StyleBoxTexture")
	print("TinySwordsTheme OK")

	print("=== UI SMOKE TEST PASS ===")
	quit(0)
