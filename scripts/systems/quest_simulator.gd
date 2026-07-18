class_name QuestSimulator
extends RefCounted


static func _gs() -> Node:
	return Engine.get_main_loop().root.get_node("GameState")


static func _balance() -> Dictionary:
	var f := FileAccess.open("res://data/balance.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _classes() -> Dictionary:
	var f := FileAccess.open("res://data/classes.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func estimate_success(party: PartyData, quest: QuestData) -> float:
	var bal: Dictionary = _balance()
	var gs: Node = _gs()
	var members: Array[HeroData] = gs.get_heroes_by_ids(party.member_ids)
	if members.is_empty():
		return 0.0

	var avg_power := 0.0
	var pref_mod := 0.0
	var cohesion := 0.0
	for h in members:
		avg_power += h.power_score()
		pref_mod += h.preference_modifier(quest.quest_type)
		for other_id in party.member_ids:
			if other_id != h.id and h.cohesion_with.has(other_id):
				cohesion += float(h.cohesion_with[other_id])

	avg_power /= float(members.size())
	pref_mod /= float(members.size())
	cohesion /= float(maxi(members.size(), 1))

	var class_weight := 1.0
	var classes: Dictionary = _classes()
	for h in members:
		var cd: Dictionary = classes.get(h.class_id, {})
		var key := "%s_weight" % quest.quest_type
		class_weight += float(cd.get(key, 1.0))
	class_weight /= float(members.size() + 1)

	var chance: float = float(bal.get("base_success_chance", 0.55))
	chance += (avg_power - 8.0) * float(bal.get("stat_success_weight", 0.02))
	chance += pref_mod * 0.5
	chance += cohesion * float(bal.get("cohesion_bonus_per_point", 0.01))
	chance += (class_weight - 1.0) * 0.15
	chance -= float(quest.difficulty - 1) * 0.12
	chance += float(members.size() - 2) * 0.03
	return clampf(chance, 0.05, 0.95)


static func resolve(party: PartyData, quest: QuestData) -> Dictionary:
	var bal: Dictionary = _balance()
	var gs: Node = _gs()
	var members: Array[HeroData] = gs.get_heroes_by_ids(party.member_ids)
	var chance := estimate_success(party, quest)
	var success: bool = randf() <= chance

	var report := {
		"success": success,
		"chance": chance,
		"quest_name": quest.quest_name,
		"party_name": party.party_name,
		"gold": 0,
		"fame": 0,
		"mana": 0,
		"deaths": [],
		"hospital": [],
		"gm_dead": false,
		"text": "",
	}

	if success:
		var gold: int = quest.gold_reward
		var share: float = float(bal.get("hero_reward_share", 0.3))
		var guild_gold: int = int(round(float(gold) * (1.0 - share)))
		report["gold"] = guild_gold
		report["fame"] = quest.fame_reward
		if randf() < quest.mana_chance:
			report["mana"] = 1
		gs.gold += guild_gold
		gs.fame += quest.fame_reward
		gs.mana_crystals += int(report["mana"])

		for h in members:
			h.add_xp(int(bal.get("xp_per_quest_success", 25)))
			h.morale = mini(100, h.morale + int(bal.get("morale_bonus_on_success", 5)))
			h.status = HeroData.Status.AVAILABLE
			for other_id in party.member_ids:
				if other_id == h.id:
					continue
				var cur: int = int(h.cohesion_with.get(other_id, 0))
				h.cohesion_with[other_id] = cur + 1

		report["text"] = "Успех! Шанс был %.0f%%. Гильдия получила %d золота." % [chance * 100.0, guild_gold]
	else:
		gs.fame = maxi(0, gs.fame - maxi(1, quest.fame_reward))
		var death_chance: float = float(bal.get("defeat_death_chance", 0.4))
		for h in members:
			h.add_xp(int(bal.get("xp_per_quest_fail", 8)))
			if randf() < 0.55:
				if randf() < death_chance:
					h.status = HeroData.Status.DEAD
					report["deaths"].append(h.display_name())
					if h.is_guildmaster:
						report["gm_dead"] = true
					for other in members:
						if other.id != h.id and other.status != HeroData.Status.DEAD:
							other.morale = maxi(0, other.morale - int(bal.get("morale_penalty_on_death", 10)))
				else:
					h.status = HeroData.Status.HOSPITAL
					var days: int = randi_range(2, 5) - int(_gs().hospital_bonus)
					h.hospital_days = maxi(1, days)
					report["hospital"].append(h.display_name())
			else:
				h.status = HeroData.Status.AVAILABLE
				h.morale = maxi(0, h.morale - 5)

		report["text"] = "Провал (шанс успеха был %.0f%%). Репутация упала." % [chance * 100.0]
		if report["deaths"].size() > 0:
			report["text"] += " Погибли: %s." % ", ".join(report["deaths"])
		if report["hospital"].size() > 0:
			report["text"] += " В госпитале: %s." % ", ".join(report["hospital"])

	party.on_mission = false
	party.assigned_quest_id = ""
	party.days_remaining = 0
	quest.taken = true
	return report
