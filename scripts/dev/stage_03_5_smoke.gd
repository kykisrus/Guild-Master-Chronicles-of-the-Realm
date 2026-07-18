extends SceneTree
## godot --path . --headless -s res://scripts/dev/stage_03_5_smoke.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== STAGE 03.5 SMOKE ===")

	var baked: ImageTexture = TinySwordsUi.bake_seamless_panel(TinySwordsUi.PAPER_SPECIAL)
	assert(baked != null, "bake SpecialPaper null")
	assert(baked.get_width() >= 24 and baked.get_height() >= 24, "bake too small")
	print("Bake SpecialPaper OK ", baked.get_width(), "x", baked.get_height())

	var btn_bake: ImageTexture = TinySwordsUi.bake_seamless_panel(TinySwordsUi.BTN_BLUE)
	assert(btn_bake != null, "bake button null")
	print("Bake button OK")

	var theme: Theme = TinySwordsThemeFactory.build()
	assert(theme != null and theme.default_font != null, "TinySwordsThemeFactory failed")
	var panel_sb := theme.get_stylebox("panel", "PanelContainer")
	assert(panel_sb is StyleBoxTexture, "panel must be StyleBoxTexture")
	var tex_sb := panel_sb as StyleBoxTexture
	assert(tex_sb.texture != null, "panel texture null")
	print("Theme factory OK")

	# Settings still on Tiny GUI
	var settings_theme: Theme = TinyThemeFactory.build()
	assert(settings_theme != null, "TinyThemeFactory failed")
	print("Settings TinyTheme OK")

	for path in [
		"res://scenes/ui/dialogue/dialogue_box.tscn",
		"res://scenes/intro/guildmaster_registration.tscn",
		"res://scenes/intro/guild_creation.tscn",
		"res://scenes/intro/intro_field.tscn",
		"res://scenes/intro/intro_barracks.tscn",
		"res://scenes/menu/main_menu.tscn",
		"res://scenes/menu/load_menu.tscn",
		"res://scenes/menu/credits_menu.tscn",
		"res://scenes/menu/settings_menu.tscn",
		"res://scripts/systems/clickable_building.gd",
		"res://scripts/ui/tiny_swords_theme_factory.gd",
	]:
		assert(ResourceLoader.exists(path), "Missing %s" % path)
		print("OK ", path)

	var err := change_scene_to_file("res://scenes/ui/dialogue/dialogue_box.tscn")
	assert(err == OK, "dialogue load failed")
	await process_frame
	await process_frame
	print("Dialogue scene load OK")

	err = change_scene_to_file("res://scenes/intro/guildmaster_registration.tscn")
	assert(err == OK, "registration load failed")
	await process_frame
	await process_frame
	print("Registration scene load OK")

	err = change_scene_to_file("res://scenes/intro/intro_field.tscn")
	assert(err == OK, "field load failed")
	await process_frame
	await process_frame
	print("Field scene load OK")

	print("=== STAGE 03.5 SMOKE PASS ===")
	quit(0)
