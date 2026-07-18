extends SceneTree

## Run: godot --path . --headless -s res://scripts/systems/smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	var ts: Node = root.get_node("TimeSystem")
	var sl: Node = root.get_node("SaveLoad")

	print("=== SMOKE TEST START ===")
	gs.new_game("Smoke Guild")
	var crest_save: Dictionary = gs.to_save_dict()
	assert(crest_save.has("guild_crest_shield"), "Shield form is not saved")
	assert(crest_save.has("guild_crest_secondary_color"), "Secondary tincture is not saved")
	assert(crest_save.has("guild_crest_charge_color"), "Charge tincture is not saved")
	assert(crest_save.has("guild_crest_border"), "Heraldry border is not saved")
	assert(gs.get_guildmaster() != null, "GM missing")
	assert(gs.heroes.size() == 1, "A new guild must start with Guildmaster only")
	assert(gs.get_guildmaster().weapon_proficiencies.size() == 8, "Weapon skills missing")
	assert(gs.get_guildmaster().magic_schools.size() == 9, "Magic schools missing")
	assert(gs.get_guildmaster().known_level == 5, "Guildmaster profile must be fully known")
	assert(gs.get_guildmaster().potential in range(2, 6), "Hero potential is invalid")
	assert(gs.get_guildmaster().max_hp() > 0, "Derived HP missing")
	var gm_xp_before: int = gs.get_guildmaster().xp
	gs.get_guildmaster().add_xp(20)
	assert(gs.get_guildmaster().xp - gm_xp_before == 25, "GM gift must grant +25% XP")
	print("GM: ", gs.get_guildmaster().display_name())

	var before: int = gs.heroes.size()
	var err: String = gs.hire_recruit(0)
	assert(err == "", "Hire failed: %s" % err)
	assert(gs.heroes.size() == before + 1, "Hire count")
	assert(gs.heroes[-1].known_level == 5, "Hired hero profile was not fully revealed")
	err = gs.hire_recruit(0)
	assert(err == "", "Second hire failed: %s" % err)
	print("Hired OK, roster=", gs.heroes.size())

	var ids := PackedStringArray()
	for h in gs.heroes:
		if h is HeroData and not h.is_guildmaster and h.status == HeroData.Status.AVAILABLE:
			ids.append(h.id)
			if ids.size() >= 2:
				break
	err = gs.create_party("Alpha", ids, false)
	assert(err == "", "Party create: %s" % err)
	var party: PartyData = gs.parties[0]
	print("Party: ", party.party_name, " size=", party.size())

	err = gs.create_party("Bad", PackedStringArray([gs.get_guildmaster().id, ids[0]]), false)
	assert(err != "", "GM should be blocked from non-GM party")
	assert(err.contains("ГМ") or err.contains("чужой"), "Expected GM rule, got: %s" % err)
	print("GM block OK: ", err)

	assert(gs.board_quests.size() > 0, "No quests")
	var quest: QuestData = gs.board_quests[0]
	err = gs.assign_quest(party.id, quest.id)
	assert(err == "", "Assign: %s" % err)
	print("Assigned quest for ", party.days_remaining, " days")

	var days: int = party.days_remaining
	for i in days:
		ts.end_day()
		if gs.is_game_over:
			break
	print("After mission: ", gs.last_report.get("text", "(no report)"))
	print("Gold=", gs.gold, " Fame=", gs.fame)

	gs.get_guildmaster().is_favorite = true
	err = sl.save_game(1)
	assert(err == "", "Save: %s" % err)
	var gold_saved: int = gs.gold
	gs.new_game("Other")
	err = sl.load_game(1)
	assert(err == "", "Load: %s" % err)
	assert(gs.gold == gold_saved, "Gold mismatch after load")
	assert(gs.get_guildmaster().weapon_proficiencies.size() == 8, "Extended stats lost after load")
	assert(gs.get_guildmaster().known_level == 5, "Hero knowledge was lost after load")
	assert(not gs.get_guildmaster().history.is_empty(), "Hero history was lost after load")
	assert(gs.get_guildmaster().is_favorite, "Favorite flag was lost after load")
	print("Save/Load OK")

	print("=== SMOKE TEST PASSED ===")
	quit(0)
