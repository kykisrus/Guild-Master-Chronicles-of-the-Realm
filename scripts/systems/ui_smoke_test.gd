extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	print("=== UI SMOKE TEST START ===")

	var splash_scene: PackedScene = load("res://scenes/ui/intro_splash.tscn")
	var splash: Node = splash_scene.instantiate()
	root.add_child(splash)
	await process_frame
	assert(root.get_node("MusicController").is_intro_playing(), "Intro music did not start with splash")
	assert(splash.get_node("%Logo").texture != null, "Engine logo was not shown first")
	splash.queue_free()
	await process_frame

	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Node = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	assert(menu.get_node("%BtnContinue") != null, "Continue button missing")
	assert(menu.get_node("%BtnLoad") != null, "Load button missing")
	assert(menu.get_node("%BtnCredits") != null, "Credits button missing")
	assert(root.get_node("MusicController").is_intro_playing(), "Intro must continue after entering main menu")
	menu.call("_on_credits")
	assert(menu.get_node("%CreditsPanel").visible, "Credits modal did not open")
	assert(not menu.get_node("%LastSavePanel").visible, "Latest guild card overlaps credits")
	assert(menu.get_node("%CreditsPanel/CreditsVBox/CreditsAuthor").text == "Kykis_rus / AMS-site", "Game author is incorrect")
	menu.call("_on_close_credits")
	menu.queue_free()
	await process_frame

	var setup_scene: PackedScene = load("res://scenes/ui/new_game_setup.tscn")
	var setup: Node = setup_scene.instantiate()
	root.add_child(setup)
	await process_frame
	assert(setup.current_step == 0, "Wizard must start with Guildmaster")
	assert(root.get_node("MusicController").is_intro_playing(), "Intro/menu music must continue during new game creation")
	root.get_node("MusicController").call("_on_track_finished")
	assert(root.get_node("MusicController").is_menu_theme_playing(), "Main menu theme did not replace finished intro")
	assert(setup.get_node("Margin/VBox/MainRow").vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "New game content must scroll on short screens")
	assert(setup.draft_gm.weapon_proficiencies.size() == 8, "Full weapon stats absent")
	assert(setup.draft_gm.magic_schools.size() == 9, "Full magic stats absent")
	assert(setup.draft_gm.skills.size() == 11, "Practical hero skills absent")
	assert(setup.draft_gm.primary_management_stats.size() == 4, "Guildmaster primary profile must contain exactly four stats")
	assert(setup.draft_gm.management_skills.size() == 15, "Guildmaster additional skills are incomplete")
	assert(setup.get_node("%PrimaryStats").get_child_count() == 4, "Primary stat bars are incomplete")
	assert(setup.call("_remaining_primary_points") == 20, "Guildmaster must start with 20 free points")
	assert(setup.get_node("Margin/VBox/Footer/BtnStart").disabled, "Next must be locked until all primary points are spent")
	assert(setup.get_node("%PortraitTexture").visible, "Default gender portrait was not loaded")
	setup.call("_on_gender_selected", 1)
	assert(setup.draft_gm.gender == "female", "Gender selection did not update profile")
	assert(setup.draft_gm.portrait_id.ends_with("portrait_default_female.png"), "Female portrait was not selected")
	assert(setup.gm_name_edit.text in HeroGenerator._load_json("res://data/names.json").get("female_first", []), "Female gender generated an incompatible first name")
	var old_skills: Dictionary = setup.draft_gm.management_skills.duplicate()
	var old_primary: Dictionary = setup.draft_gm.primary_management_stats.duplicate()
	setup.call("_on_reroll_skills")
	assert(setup.draft_gm.primary_management_stats == old_primary, "Additional reroll changed primary stats")
	assert(setup.draft_gm.management_skills != old_skills, "Additional skills did not reroll")
	var portrait_before: String = setup.draft_gm.portrait_id
	setup.call("_on_random_primary")
	assert(setup.call("_remaining_primary_points") == 0, "Random allocation did not spend all points")
	assert(not setup.get_node("Margin/VBox/Footer/BtnStart").disabled, "Next stayed locked after allocating all points")
	assert(setup.draft_gm.portrait_id == portrait_before, "Primary reroll changed portrait")
	setup.call("_on_open_skills")
	assert(setup.get_node("%SkillsModalShade").visible, "Additional skills modal did not open")
	setup.call("_on_close_skills")
	assert(not setup.get_node("%SkillsModalShade").visible, "Additional skills modal did not close")
	setup.call("_on_random_crest")
	assert(not setup.selected_shield.is_empty(), "Shield form was not generated")
	assert(not setup.selected_secondary_color.is_empty(), "Secondary tincture was not generated")
	assert(not setup.selected_charge_color.is_empty(), "Charge tincture was not generated")
	assert(setup.crest_seed != 0, "Heraldry seed is missing")
	setup.call("_on_start")
	assert(setup.current_step == 1, "Guild step did not open")
	var heraldry_scroll: ScrollContainer = setup.get_node("Margin/VBox/MainRow/GuildPanel/GuildVBox/HeraldryRow/HeraldryControls")
	assert(heraldry_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS, "Heraldry scrollbar must stay visible")
	assert(not setup.get_node("Margin/VBox/MainRow/GuildPanel/GuildVBox/GuildTop/PreviewBox").visible, "Duplicate crest preview is still visible")
	assert(setup.get_node("%LargeCrestPreview").get_child_count() >= 1, "Large crest preview is missing")
	var main_row: Control = setup.get_node("Margin/VBox/MainRow")
	var footer: Control = setup.get_node("Margin/VBox/Footer")
	assert(main_row.get_global_rect().end.y <= footer.get_global_rect().position.y + 1.0, "Footer overlaps scrollable content")
	setup.call("_on_heraldry_tab", 1)
	assert(not setup.get_node("%ShapeGrid").visible and setup.get_node("%PatternGrid").visible, "Heraldry tabs do not switch sections")
	setup.call("_on_start")
	assert(setup.current_step == 2, "Prologue step did not open")
	assert(not setup.story_text.text.is_empty(), "Prologue was not generated")
	setup.queue_free()
	await process_frame

	var gs: Node = root.get_node("GameState")
	gs.new_game("UI Test Guild")
	var game_scene: PackedScene = load("res://scenes/game/main.tscn")
	var game: Node = game_scene.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.get_node("%TabBar").get_child_count() > 0, "Game navigation missing")
	assert(game.get_node("%TopInner").get_child_count() > 0, "Top bar missing")
	assert(game.get_node("%Content").size.x > 0, "Content did not receive available width")
	assert(game.get_node("%SideNav").size.y == game.size.y, "Sidebar does not fill the shell")
	assert(not game.get_node("Background").visible, "Legacy game UI background is still visible")
	var pixel_panel := UIStyle.kenney_frame_style(UIStyle.BORDER, 11, 17, UIStyle.BG_PANEL)
	var pixel_image := pixel_panel.texture.get_image()
	assert(pixel_image.get_pixel(25, 25).a == 1.0, "Pixel panel center must be opaque")
	assert(pixel_panel.texture is ImageTexture, "UI frame must be composed from the Kenney sprite into one layer")
	assert(game.get_node("%GameMusic").stream != null, "Game playlist did not select a track")
	assert(game.get_node("%GameMusic").playing, "Game music did not start")
	assert(game._nav_items.size() == 11, "Simplified navigation must contain 11 major sections")
	assert(gs.get_building_defs().size() == 11, "Guild hall is missing documented buildings")
	for nav_index in game._nav_items.size():
		game.call("_navigate_to_index", nav_index)
		assert(game.get_node("%Content").get_child_count() >= 1, "Navigation entry did not build a page: %s" % game._nav_items[nav_index]["title"])
	var world_nav := -1
	for i in game._nav_items.size():
		if game._nav_items[i]["title"] == "Карта мира":
			world_nav = i
			break
	assert(world_nav >= 0, "World map navigation is missing")
	game.call("_navigate_to_index", world_nav)
	await process_frame
	var world_canvas: Control = game.get_node("%Content").find_child("WorldMapCanvas", true, false)
	assert(world_canvas != null, "Interactive world map was not built")
	var location_buttons := 0
	for child in world_canvas.get_children():
		if child.name.begins_with("Location_"):
			location_buttons += 1
	assert(location_buttons >= 6, "World map locations are incomplete")
	assert(game.get_node("%Content").find_child("WorldLocationDetails", true, false) != null, "Selected location details are missing")
	assert(game.get_node("%Content").find_child("DungeonMinimap", true, false) != null, "Dungeon minimap is missing")
	var route_a: Array = game.call("_generate_dungeon_route", 1001)
	var route_b: Array = game.call("_generate_dungeon_route", 1001)
	assert(route_a == route_b and route_a.size() >= 14, "Dungeon generation is not deterministic")
	for i in range(1, route_a.size()):
		var step: Vector2i = route_a[i] - route_a[i - 1]
		assert(absi(step.x) + absi(step.y) == 1, "Dungeon route contains a disconnected step")
	var dungeon_a: DungeonData = DungeonGenerator.generate(837261, 2)
	var dungeon_b: DungeonData = DungeonGenerator.generate(837261, 2)
	assert(dungeon_a.rooms == dungeon_b.rooms, "Same dungeon seed generated different graphs")
	assert(dungeon_a.rooms[0].type == "entrance", "Dungeon entrance is missing")
	var boss_rooms := dungeon_a.rooms.filter(func(room): return room.type == "boss")
	assert(boss_rooms.size() == 1, "Dungeon must contain exactly one boss")
	var reachable: Dictionary = {"room_0": true}
	var frontier: Array[String] = ["room_0"]
	while not frontier.is_empty():
		var room_id: String = frontier.pop_front()
		for next_id in dungeon_a.room_by_id(room_id).next:
			if not reachable.has(str(next_id)):
				reachable[str(next_id)] = true
				frontier.append(str(next_id))
	assert(reachable.has(str(boss_rooms[0].id)), "Dungeon boss is unreachable")
	game.selected_world_location = "ruins"
	game.call("_open_dungeon_simulation")
	await process_frame
	assert(game.get_node("%Content").find_child("DungeonSimulationScreen", true, false) != null, "Dungeon simulation screen did not open")
	assert(game.get_node("%Content").find_child("DungeonGraphMap", true, false) != null, "Dungeon graph map is missing")
	var explored_before: int = game.active_dungeon.explored_rooms.size()
	game.call("_advance_dungeon_simulation")
	assert(game.active_dungeon.explored_rooms.size() >= explored_before, "Dungeon simulation lost exploration progress")
	game.dungeon_simulation_open = false
	var heroes_nav := -1
	for i in game._nav_items.size():
		if game._nav_items[i]["title"] == "Герои":
			heroes_nav = i
			break
	assert(heroes_nav >= 0, "Heroes navigation is missing")
	game.roster_detail_mode = false
	game.call("_navigate_to_index", heroes_nav)
	await process_frame
	var table_rows: Control = game.get_node("%Content").find_child("HeroesTableRows", true, false)
	assert(table_rows != null and table_rows.get_child_count() == gs.heroes.size(), "Heroes table rows are incomplete")
	assert(game.get_node("%Content").find_child("HeroesTableScroll", true, false) != null, "Heroes table is not scrollable")
	game.selected_hero_id = gs.get_guildmaster().id
	game.roster_detail_mode = true
	game.call("_refresh")
	await process_frame
	var full_details: Control = game.get_node("%Content").find_child("HeroFullDetails", true, false)
	assert(full_details != null, "Full-screen hero details did not open")
	assert(full_details.find_child("HeroDetailsBack", true, false) != null, "Back button is missing from hero details")
	var profile_tabs: Control = full_details.find_child("HeroProfileTabs", true, false)
	assert(profile_tabs != null and profile_tabs.get_child_count() == 3, "Attributes/Biography/History tabs are incomplete")
	assert(full_details.find_child("HeroManagementActions", true, false) != null, "Hero management actions are missing")
	assert(ResourceLoader.exists(gs.get_guildmaster().portrait_id), "Known hero portrait does not load")
	assert(gs.toggle_hero_favorite(gs.get_guildmaster().id).is_empty() and gs.get_guildmaster().is_favorite, "Favorite toggle does not work")
	gs.get_guildmaster().level = 10
	gs.fame = 10
	assert(gs.promotion_info(gs.get_guildmaster()).get("available", false), "Eligible hero promotion is unavailable")
	assert(gs.promote_hero(gs.get_guildmaster().id).is_empty() and gs.get_guildmaster().rank == "D", "Hero promotion does not work")
	var unknown: HeroData = gs.tavern_recruits[0]
	var knowledge_before: int = unknown.known_level
	game.call("_study_candidate", unknown, 3, 0)
	assert(unknown.known_level >= 3 and unknown.known_level > knowledge_before, "Unknown hero study action does not reveal data")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1280, 800)]:
		root.size = viewport_size
		await process_frame
		game.roster_detail_mode = false
		game.call("_navigate_to_index", heroes_nav)
		await process_frame
		assert(game.get_node("%Content").find_child("HeroesTableRows", true, false) != null, "Heroes table broke at %s" % viewport_size)
	assert(game.call("_building_def", "forge").get("name", "") == "Кузница", "Forge screen is not connected")
	assert(game.call("_building_def", "laboratory").get("name", "") == "Магическая лаборатория", "Laboratory screen is not connected")
	assert(game.call("_building_def", "library").get("name", "") == "Архив знаний", "Archive screen is not connected")
	assert(gs.heroes.size() == 1, "New game must not add starter heroes")
	var staff_before: int = gs.npc_staff
	assert(gs.hire_staff_candidate(0).is_empty() and gs.npc_staff == staff_before + 1, "Typed staff hiring does not work")
	var trainer_index := -1
	for i in gs.staff_candidates.size():
		if gs.staff_candidates[i].get("role", "") == "trainer":
			trainer_index = i
			break
	assert(trainer_index >= 0, "Trainer candidate is missing")
	gs.gold = 2000
	assert(gs.hire_staff_candidate(trainer_index).is_empty(), "Trainer hiring failed")
	assert(gs.has_staff_role("trainer"), "Trainer role was not registered")
	assert(gs.upgrade_building("arena").is_empty(), "Arena construction failed")
	assert(gs.hire_recruit(0).is_empty(), "Hero required for training could not be hired")
	assert(gs.run_facility_action("arena").is_empty(), "Arena training with Master NPC failed")
	for hero in gs.heroes:
		if hero is HeroData and not hero.is_guildmaster:
			hero.str_stat = 20
			hero.dex_stat = 20
			hero.con_stat = 20
	seed(7)
	for attempt in 50:
		gs.process_autonomous_quest_choices()
		if not gs.parties.is_empty():
			break
	assert(not gs.parties.is_empty(), "Heroes never selected a board quest autonomously")
	var dashboard: Control = game.call("_build_dashboard")
	assert(dashboard != null and dashboard.get_child_count() >= 4, "Overview dashboard cards are missing")
	dashboard.queue_free()
	game.queue_free()

	print("=== UI SMOKE TEST PASSED ===")
	quit(0)
