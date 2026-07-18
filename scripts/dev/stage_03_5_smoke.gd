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

	var btn_style: StyleBoxTexture = TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN)
	assert(btn_style.texture != null, "button style texture null")
	assert(btn_style.texture_margin_top <= TinySwordsUi.DEFAULT_MAX_TEX_MARGIN + 1, "button margin not capped")
	print("Button style margins OK t=", btn_style.texture_margin_top)

	var bar: StyleBoxTexture = TinySwordsUi.style_horizontal_bar(TinySwordsUi.WOOD_TABLE, 8, 12)
	assert(bar.texture != null, "wood bar null")
	assert(is_equal_approx(bar.texture_margin_top, 0.0), "bar must not 9-slice vertically")
	assert(bar.texture_margin_left <= 12.0 + 0.5, "bar side margin capped")
	assert(bar.texture.get_height() >= 24, "wood bar too short")
	print("Wood bar OK h=", bar.texture.get_height(), " ml=", bar.texture_margin_left)

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
