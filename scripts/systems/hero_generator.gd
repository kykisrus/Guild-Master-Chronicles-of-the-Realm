class_name HeroGenerator
extends RefCounted


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _balance() -> Dictionary:
	return _load_json("res://data/balance.json")


static func _classes() -> Dictionary:
	return _load_json("res://data/classes.json")


static func random_name(force_gender: String = "") -> String:
	var names: Dictionary = _load_json("res://data/names.json")
	var male: Array = names.get("male_first", names.get("first", ["Герой"]))
	var female: Array = names.get("female_first", male)
	var lasts: Array = names.get("last_names", names.get("last", ["Безымянный"]))
	var nouns: Array = names.get("nouns", [])
	var titles: Array = names.get("titles", [])

	var use_female := false
	if force_gender == "female":
		use_female = true
	elif force_gender == "male":
		use_female = false
	else:
		use_female = randf() < 0.45

	var firsts: Array = female if use_female else male
	if firsts.is_empty():
		firsts = ["Герой"]
	var first: String = str(firsts[randi() % firsts.size()])

	var last_part: String
	if nouns.size() > 0 and lasts.size() > 0 and randf() < 0.55:
		last_part = "%s %s" % [str(lasts[randi() % lasts.size()]), str(nouns[randi() % nouns.size()])]
	elif lasts.size() > 0:
		last_part = str(lasts[randi() % lasts.size()])
	else:
		last_part = "Безымянный"

	if titles.size() > 0 and randf() < 0.25:
		return "%s %s %s" % [first, last_part, str(titles[randi() % titles.size()])]
	return "%s %s" % [first, last_part]


static func random_first_name(female: bool = false) -> String:
	var names: Dictionary = _load_json("res://data/names.json")
	var pool: Array = names.get("female_first" if female else "male_first", ["Герой"])
	if pool.is_empty():
		return "Герой"
	return str(pool[randi() % pool.size()])


static func random_identity(gender: String) -> Dictionary:
	var names: Dictionary = _load_json("res://data/names.json")
	var female := gender == "female"
	var first_pool: Array = names.get("female_first" if female else "male_first", ["Герой"])
	var surname_pool: Array = names.get("nouns", ["Вальк", "Гребень", "Буря"])
	var gendered: Array = [
		{"male": "Суровый", "female": "Суровая"},
		{"male": "Мудрый", "female": "Мудрая"},
		{"male": "Безмолвный", "female": "Безмолвная"},
		{"male": "Железный", "female": "Железная"},
		{"male": "Странник", "female": "Странница"},
	]
	var universal: Array = ["Серое Перо", "Голос Бури", "Клинок Рассвета", "Хранитель Порога"]
	var nickname: String = str(universal.pick_random()) if randf() < 0.55 else str(gendered.pick_random()[gender])
	return {
		"first_name": str(first_pool.pick_random()),
		"last_name": str(surname_pool.pick_random()),
		"nickname": nickname,
	}


static func _roll_stat(min_v: int, max_v: int) -> int:
	return randi_range(min_v, max_v)


static func _apply_class_bias(h: HeroData, class_id: String) -> void:
	var classes: Dictionary = _classes()
	if not classes.has(class_id):
		return
	var primaries: Array = classes[class_id].get("primary_stats", [])
	for s in primaries:
		match str(s):
			"str":
				h.str_stat += 2
			"dex":
				h.dex_stat += 2
			"con":
				h.con_stat += 2
			"int":
				h.int_stat += 2
			"wis":
				h.wis_stat += 2
			"cha":
				h.cha_stat += 2


static func _set_class(h: HeroData, class_id: String) -> void:
	h.class_id = class_id
	var classes: Dictionary = _classes()
	if classes.has(class_id):
		h.class_display = str(classes[class_id].get("name", class_id))
	else:
		h.class_display = class_id


static func _roll_preferences(h: HeroData) -> void:
	var pool := ["combat", "gathering", "escort"]
	pool.shuffle()
	h.likes = PackedStringArray([pool[0]])
	h.dislikes = PackedStringArray([pool[1]])
	if randf() < 0.12:
		h.likes = PackedStringArray(["pacifist"])
		h.dislikes = PackedStringArray(["combat"])


static func _roll_extended_profile(h: HeroData) -> void:
	var kingdoms := [
		"Свободные Земли", "Валенор", "Элдорин", "Лирия", "Астара", "Громтар",
		"Фростхольм", "Дварфхолд", "Сильвария", "Зараш", "Тал'Мара",
	]
	h.gender = "female" if randf() < 0.45 else "male"
	h.age = randi_range(18, 65)
	h.home_kingdom = str(kingdoms.pick_random())
	h.origin = [
		"городская семья", "пограничное поселение", "старый воинский род",
		"семья ремесленников", "странствующие авантюристы", "ученики храма",
	].pick_random()
	h.potential = randi_range(2, 5)
	h.biography_short = "%s вырос%s в регионе «%s» и выбрал%s путь искателя приключений после события, изменившего привычную жизнь." % [
		h.hero_name if not h.hero_name.is_empty() else "Герой", "ла" if h.gender == "female" else "",
		h.home_kingdom, "а" if h.gender == "female" else "",
	]
	h.personal_goal = [
		"Стать признанным мастером своего ремесла.",
		"Раскрыть тайну собственного происхождения.",
		"Защитить тех, кто не может постоять за себя.",
		"Найти след давнего врага.",
	].pick_random()
	for key in h.weapon_proficiencies.keys():
		h.weapon_proficiencies[key] = randi_range(0, 5)
	for key in h.magic_schools.keys():
		h.magic_schools[key] = randi_range(0, 4)
	h.skills["athletics"] = maxi(0, int(round((h.str_stat + h.con_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["acrobatics"] = maxi(0, h.dex_stat + randi_range(-2, 2))
	h.skills["stealth"] = maxi(0, int(round((h.dex_stat + h.wis_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["perception"] = maxi(0, h.wis_stat + randi_range(-2, 2))
	h.skills["survival"] = maxi(0, int(round((h.con_stat + h.wis_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["medicine"] = maxi(0, int(round((h.int_stat + h.wis_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["diplomacy"] = maxi(0, h.cha_stat + randi_range(-2, 2))
	h.skills["intimidation"] = maxi(0, int(round((h.str_stat + h.cha_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["crafting"] = maxi(0, int(round((h.dex_stat + h.int_stat) / 2.0)) + randi_range(-2, 2))
	h.skills["alchemy"] = maxi(0, h.int_stat + randi_range(-3, 1))
	h.skills["lore"] = maxi(0, int(round((h.int_stat + h.wis_stat) / 2.0)) + randi_range(-2, 2))
	match h.class_id:
		"warrior":
			h.weapon_proficiencies["one_handed"] += randi_range(4, 8)
			h.weapon_proficiencies["two_handed"] += randi_range(3, 7)
			h.weapon_proficiencies["polearms"] += randi_range(3, 7)
		"archer":
			h.weapon_proficiencies["bows"] += randi_range(5, 9)
			h.weapon_proficiencies["crossbows"] += randi_range(3, 7)
			h.weapon_proficiencies["light_blades"] += randi_range(2, 5)
		"mage":
			for key in ["fire", "ice", "lightning", "earth", "illusion", "arcana"]:
				h.magic_schools[key] += randi_range(3, 7)
		"acolyte":
			h.magic_schools["light"] += randi_range(5, 9)
			h.magic_schools["earth"] += randi_range(2, 5)
			h.weapon_proficiencies["unarmed"] += randi_range(3, 7)
		"summoner":
			h.magic_schools["summoning"] += randi_range(6, 10)
			h.magic_schools["arcana"] += randi_range(2, 6)
		"rogue":
			h.weapon_proficiencies["light_blades"] += randi_range(6, 10)
			h.weapon_proficiencies["throwing"] += randi_range(3, 7)
		"druid":
			h.magic_schools["earth"] += randi_range(6, 10)
			h.magic_schools["summoning"] += randi_range(3, 7)
		"bard":
			h.magic_schools["illusion"] += randi_range(4, 8)
			h.weapon_proficiencies["light_blades"] += randi_range(2, 6)


static func create_guildmaster() -> HeroData:
	var bal: Dictionary = _balance()
	var h := HeroData.new()
	h.id = "gm"
	h.is_guildmaster = true
	var class_ids: Array = _classes().keys()
	_set_class(h, str(class_ids[randi() % class_ids.size()]))
	var mn: int = int(bal.get("gm_stat_min", 6))
	var mx: int = int(bal.get("gm_stat_max", 14))
	h.str_stat = _roll_stat(mn, mx)
	h.dex_stat = _roll_stat(mn, mx)
	h.con_stat = _roll_stat(mn, mx)
	h.int_stat = _roll_stat(mn, mx)
	h.wis_stat = _roll_stat(mn, mx)
	h.cha_stat = _roll_stat(mn, mx)
	_apply_class_bias(h, h.class_id)
	h.alignment = randi_range(0, 5)
	h.level = 1
	h.rank = "E"
	h.morale = 80
	h.loyalty = 100
	_roll_preferences(h)
	_roll_extended_profile(h)
	var identity := random_identity(h.gender)
	h.hero_name = str(identity["first_name"])
	h.last_name = str(identity["last_name"])
	h.nickname = str(identity["nickname"])
	h.biography_short = "%s %s вырос%s в регионе «%s» и со временем решил%s основать собственную гильдию." % [
		h.hero_name, h.last_name, "ла" if h.gender == "female" else "",
		h.home_kingdom, "а" if h.gender == "female" else "",
	]
	for key in h.primary_management_stats:
		h.primary_management_stats[key] = 5
	randomize_guildmaster_skills(h)
	h.temperament = ["Сангвиник", "Холерик", "Флегматик", "Меланхолик"].pick_random()
	h.rare_gift = [
		"Взгляд Гильдмастера", "Голос авторитета", "Магическая интуиция",
		"Чувство опасности", "Прирождённый дипломат", "Военный гений",
		"Печать лидера", "Хранитель клятв",
	].pick_random()
	h.weakness = [
		"Низкая выносливость", "Недоверие к магам", "Склонность к риску",
		"Плохое управление финансами", "Слабая стрессоустойчивость",
		"Трудности с дипломатией", "Медленное обучение",
	].pick_random()
	if h.rare_gift == "Прирождённый дипломат":
		while h.weakness == "Трудности с дипломатией":
			h.weakness = [
				"Низкая выносливость", "Недоверие к магам", "Склонность к риску",
				"Плохое управление финансами", "Слабая стрессоустойчивость", "Медленное обучение",
			].pick_random()
	h.portrait_id = "res://assets/portraits/portrait_default_%s.png" % h.gender
	h.known_level = 5
	h.history = PackedStringArray(["День 1 — основал гильдию."])
	return h


static func randomize_guildmaster_primary(h: HeroData) -> void:
	for key in h.primary_management_stats:
		h.primary_management_stats[key] = 5
	var keys: Array = h.primary_management_stats.keys()
	for point in 20:
		var available := keys.filter(func(key): return int(h.primary_management_stats[key]) < 15)
		var key: String = str(available.pick_random())
		h.primary_management_stats[key] = int(h.primary_management_stats[key]) + 1
	# Charisma also informs the hero's existing combat/social sheet.
	h.cha_stat = int(h.primary_management_stats["charisma"])
	h.skills["diplomacy"] = int(h.primary_management_stats["diplomacy"])


static func randomize_guildmaster_skills(h: HeroData) -> void:
	var relations := {
		"strategy": "leadership", "tactics": "leadership", "staff_management": "leadership",
		"warfare": "leadership", "training": "charisma", "psychology": "charisma",
		"trade": "diplomacy", "reputation": "diplomacy", "finance": "influence",
		"organization": "influence", "logistics": "influence", "scouting": "influence",
		"crafting": "influence", "arcane_knowledge": "charisma", "stress_resistance": "leadership",
	}
	for key in h.management_skills:
		var primary: int = int(h.primary_management_stats.get(relations.get(key, "influence"), 5))
		h.management_skills[key] = clampi(randi_range(2, 15) + int(primary / 4.0), 1, 20)


static func create_hero(level: int = 1) -> HeroData:
	var bal: Dictionary = _balance()
	var h := HeroData.new()
	h.id = "h_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]
	h.hero_name = random_name()
	var class_ids: Array = _classes().keys()
	_set_class(h, str(class_ids[randi() % class_ids.size()]))
	var mn: int = int(bal.get("hero_stat_min", 5))
	var mx: int = int(bal.get("hero_stat_max", 12))
	h.str_stat = _roll_stat(mn, mx)
	h.dex_stat = _roll_stat(mn, mx)
	h.con_stat = _roll_stat(mn, mx)
	h.int_stat = _roll_stat(mn, mx)
	h.wis_stat = _roll_stat(mn, mx)
	h.cha_stat = _roll_stat(mn, mx)
	_apply_class_bias(h, h.class_id)
	h.alignment = randi_range(0, 8)
	h.level = level
	h._update_rank()
	_roll_preferences(h)
	_roll_extended_profile(h)
	h.portrait_id = "res://assets/portraits/portrait_default_%s.png" % h.gender
	h.known_level = 1
	h.history = PackedStringArray(["Кандидат появился в списке рекрутинга."])
	return h


static func hire_cost(hero: HeroData) -> int:
	var bal: Dictionary = _balance()
	return int(bal.get("hire_cost_base", 80)) + hero.level * int(bal.get("hire_cost_per_level", 15))
