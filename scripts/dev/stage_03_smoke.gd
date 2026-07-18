extends SceneTree
## godot --path . --headless -s res://scripts/dev/stage_03_smoke.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== STAGE 03 SMOKE ===")

	var required := [
		"res://scenes/intro/intro_field.tscn",
		"res://scenes/intro/intro_barracks.tscn",
		"res://scenes/intro/guildmaster_registration.tscn",
		"res://scenes/intro/guild_creation.tscn",
		"res://scenes/guild_hub/guild_hub.tscn",
		"res://scenes/characters/guildmaster.tscn",
		"res://scenes/ui/dialogue/dialogue_box.tscn",
		"res://data/intro/thief_dialogue.json",
		"res://autoload/campaign_state.gd",
	]
	for path in required:
		assert(ResourceLoader.exists(path), "Missing %s" % path)
		print("OK ", path)

	var campaign: Node = root.get_node("CampaignState")
	var save_load: Node = root.get_node("SaveLoad")
	assert(save_load.CURRENT_SAVE_VERSION == 1, "save version must be 1")

	# Skip-path style: registration data → found guild → save → load hub
	campaign.reset()
	campaign.set_pending_guildmaster({
		"first_name": "Иван",
		"last_name": "Тестов",
		"age": 32,
		"origin": "Странник",
		"origin_key": "gm_registration.origin.wanderer",
		"gender": "male",
	})
	campaign.set_pending_guild("Дымовая Застава", "blue")
	campaign.found_guild()
	assert(bool(campaign.flags.get("intro_completed", false)))
	assert(bool(campaign.flags.get("thief_left", false)))
	assert(str(campaign.guild.get("name", "")) == "Дымовая Застава")

	var slot: int = save_load.first_writable_slot()
	var err: String = save_load.save_campaign(slot)
	assert(err == "", "save failed: %s" % err)
	assert(save_load.get_slot_status(slot) == save_load.SlotStatus.AVAILABLE)

	campaign.reset()
	err = save_load.load_campaign(slot)
	assert(err == "", "load failed: %s" % err)
	assert(campaign.guild_display_name() == "Дымовая Застава")

	var scene_err := change_scene_to_file("res://scenes/guild_hub/guild_hub.tscn")
	assert(scene_err == OK, "hub scene failed")
	await process_frame
	await process_frame
	assert(root.get_child_count() > 0)
	assert(root.get_node_or_null("GuildHub") != null or _find_scene_root("GuildHub") != null, "GuildHub missing")

	scene_err = change_scene_to_file("res://scenes/menu/main_menu.tscn")
	assert(scene_err == OK, "menu failed")
	await process_frame

	scene_err = change_scene_to_file("res://scenes/intro/guildmaster_registration.tscn")
	assert(scene_err == OK, "registration failed")
	await process_frame
	assert(_find_scene_root("GuildmasterRegistration") != null, "registration missing")

	scene_err = change_scene_to_file("res://scenes/intro/intro_field.tscn")
	assert(scene_err == OK, "intro field failed")
	await process_frame
	await process_frame

	print("=== STAGE 03 SMOKE PASS ===")
	quit(0)


func _find_scene_root(node_name: String) -> Node:
	for child in root.get_children():
		if str(child.name) == node_name:
			return child
		var nested := child.get_node_or_null(node_name)
		if nested != null:
			return nested
	return null
