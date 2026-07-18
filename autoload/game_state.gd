extends Node

signal state_changed
signal notifications_changed
signal game_over(reason: String)
signal quest_resolved(report: Dictionary)

var balance: Dictionary = {}
var classes_data: Dictionary = {}
var quest_templates: Dictionary = {}
var buildings_data: Dictionary = {}

var guild_name: String = "Новая Гильдия"
var guild_level: int = 1
var guild_crest_emblem: String = "star"
var guild_crest_color: String = "crimson"
var guild_crest_pattern: String = "solid"
var guild_crest_shield: String = "heater"
var guild_crest_secondary_color: String = "ivory"
var guild_crest_charge_color: String = "gold"
var guild_crest_border: String = "gold_simple"
var guild_crest_seed: int = 0
var guild_origin: String = "Свободная гильдия"
var intro_story: String = ""
var gold: int = 0
var mana_crystals: int = 0
var fame: int = 0
var food: int = 0
var debt: int = 0
var roster_slots: int = 10
var npc_staff: int = 1
var staff_working: bool = true
var staff_members: Array = []
var staff_candidates: Array = []
var building_levels: Dictionary = {} ## id -> level
var tavern_bonus: int = 0
var hospital_bonus: int = 0

var heroes: Array = [] ## Array of HeroData
var parties: Array = [] ## Array of PartyData
var board_quests: Array = [] ## Array of QuestData
var tavern_recruits: Array = [] ## Array of HeroData
var notifications: PackedStringArray = PackedStringArray()
var last_report: Dictionary = {}
var is_game_over: bool = false
var tutorial_seen: bool = false

var _next_party_num: int = 1
var _quest_seq: int = 1


func _ready() -> void:
	_load_static_data()


func _load_static_data() -> void:
	balance = _read_json("res://data/balance.json")
	classes_data = _read_json("res://data/classes.json")
	quest_templates = _read_json("res://data/quest_templates.json")
	buildings_data = _read_json("res://data/buildings.json")


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func new_game(p_guild_name: String = "Новая Гильдия") -> void:
	new_game_with_gm(p_guild_name, HeroGenerator.create_guildmaster())


func new_game_with_gm(p_guild_name: String, gm: HeroData, crest_emblem: String = "star", crest_color: String = "crimson", crest_pattern: String = "solid", p_guild_origin: String = "Свободная гильдия", p_intro_story: String = "", crest_shield: String = "heater", crest_secondary: String = "ivory", crest_charge: String = "gold", crest_border: String = "gold_simple", crest_seed: int = 0) -> void:
	is_game_over = false
	guild_name = p_guild_name
	guild_crest_emblem = crest_emblem
	guild_crest_color = crest_color
	guild_crest_pattern = crest_pattern
	guild_crest_shield = crest_shield
	guild_crest_secondary_color = crest_secondary
	guild_crest_charge_color = crest_charge
	guild_crest_border = crest_border
	guild_crest_seed = crest_seed
	guild_origin = p_guild_origin
	intro_story = p_intro_story
	guild_level = 1
	gold = int(balance.get("starting_gold", 500))
	mana_crystals = int(balance.get("starting_mana_crystals", 5))
	fame = int(balance.get("starting_fame", 0))
	food = int(balance.get("starting_food", 50))
	debt = 0
	roster_slots = int(balance.get("roster_start_slots", 10))
	npc_staff = 0
	staff_working = true
	staff_members = []
	refresh_staff_candidates()
	building_levels = {}
	tavern_bonus = 0
	hospital_bonus = 0
	for b in buildings_data.get("buildings", []):
		building_levels[str(b.get("id", ""))] = 0
	heroes.clear()
	parties.clear()
	board_quests.clear()
	tavern_recruits.clear()
	notifications = PackedStringArray()
	last_report = {}
	_next_party_num = 1
	_quest_seq = 1
	tutorial_seen = not Settings.show_tutorial

	TimeSystem.reset()

	heroes.append(gm)
	refresh_quest_board()
	refresh_tavern()
	add_notification("Гильдия «%s» основана. Редкий дар Гильдмастера пробудился." % guild_name)
	if Settings.show_tutorial and not tutorial_seen:
		add_notification("Подсказка: наймите героя во вкладке Рекрутинг, соберите отряд, отправьте на квест.")
	emit_signal("state_changed")


func clear_campaign() -> void:
	heroes.clear()
	parties.clear()
	board_quests.clear()
	tavern_recruits.clear()
	notifications = PackedStringArray()
	last_report = {}
	is_game_over = false
	guild_name = ""
	guild_level = 1
	guild_crest_emblem = "star"
	guild_crest_color = "crimson"
	guild_crest_pattern = "solid"
	guild_crest_shield = "heater"
	guild_crest_secondary_color = "ivory"
	guild_crest_charge_color = "gold"
	guild_crest_border = "gold_simple"
	guild_crest_seed = 0
	guild_origin = "Свободная гильдия"
	intro_story = ""
	gold = 0
	mana_crystals = 0
	fame = 0
	food = 0
	debt = 0
	building_levels = {}
	tavern_bonus = 0
	hospital_bonus = 0
	TimeSystem.reset()
	emit_signal("state_changed")


func get_crest_color() -> Color:
	return get_crest_color_by_id(guild_crest_color)


func get_crest_color_by_id(color_id: String) -> Color:
	var data: Dictionary = _read_json("res://data/crests.json")
	for c in data.get("colors", []):
		if str(c.get("id", "")) == color_id:
			return Color(str(c.get("hex", "#8b2e2e")))
	return Color("8b2e2e")


func get_crest_config() -> Dictionary:
	return {
		"primary": get_crest_color_by_id(guild_crest_color),
		"secondary": get_crest_color_by_id(guild_crest_secondary_color),
		"charge": get_crest_color_by_id(guild_crest_charge_color),
		"emblem": guild_crest_emblem,
		"pattern": guild_crest_pattern,
		"shield": guild_crest_shield,
		"border": guild_crest_border,
	}


func get_guildmaster() -> HeroData:
	for h in heroes:
		if h is HeroData and h.is_guildmaster:
			return h
	return null


func get_hero(hero_id: String) -> HeroData:
	for h in heroes:
		if h is HeroData and h.id == hero_id:
			return h
	return null


func get_heroes_by_ids(ids: PackedStringArray) -> Array[HeroData]:
	var result: Array[HeroData] = []
	for id in ids:
		var h := get_hero(id)
		if h != null:
			result.append(h)
	return result


func living_roster_count() -> int:
	var n := 0
	for h in heroes:
		if h is HeroData and h.status != HeroData.Status.DEAD and not h.is_guildmaster:
			n += 1
	## GM also occupies a conceptual slot but roster limit is for hired heroes
	return n


func can_hire() -> bool:
	return living_roster_count() < roster_slots


func add_notification(text: String) -> void:
	notifications.append(text)
	while notifications.size() > 30:
		notifications.remove_at(0)
	emit_signal("notifications_changed")


func refresh_quest_board() -> void:
	board_quests.clear()
	var templates: Array = quest_templates.get("templates", [])
	if templates.is_empty():
		return
	var count := mini(5, templates.size())
	var shuffled: Array = templates.duplicate()
	shuffled.shuffle()
	for i in count:
		board_quests.append(_quest_from_template(shuffled[i]))
	emit_signal("state_changed")


func _quest_from_template(t: Dictionary) -> QuestData:
	var q := QuestData.new()
	q.id = "q_%d" % _quest_seq
	_quest_seq += 1
	q.template_id = str(t.get("id", ""))
	q.quest_name = str(t.get("name", "Квест"))
	q.quest_type = str(t.get("type", "combat"))
	q.difficulty = int(t.get("difficulty", 1))
	q.duration_days = randi_range(int(balance.get("quest_duration_min", 2)), int(balance.get("quest_duration_max", 5)))
	q.gold_reward = randi_range(int(t.get("gold_min", 40)), int(t.get("gold_max", 100)))
	q.fame_reward = randi_range(int(t.get("fame_min", 0)), int(t.get("fame_max", 2)))
	q.mana_chance = float(t.get("mana_chance", 0.1))
	return q


func refresh_tavern() -> void:
	tavern_recruits.clear()
	var count := 4 + tavern_bonus
	var max_lvl := 1 + tavern_bonus
	for i in count:
		tavern_recruits.append(HeroGenerator.create_hero(randi_range(1, max_lvl)))
	emit_signal("state_changed")


func get_building_level(building_id: String) -> int:
	return int(building_levels.get(building_id, 0))


func upgrade_building(building_id: String) -> String:
	var def: Dictionary = {}
	for b in buildings_data.get("buildings", []):
		if str(b.get("id", "")) == building_id:
			def = b
			break
	if def.is_empty():
		return "Здание не найдено."
	var lvl: int = get_building_level(building_id)
	var max_lvl: int = int(def.get("max_level", 3))
	if lvl >= max_lvl:
		return "Максимальный уровень."
	var cost: int = int(def.get("gold_base", 100)) + lvl * int(def.get("gold_per_level", 50))
	if gold < cost:
		return "Недостаточно золота (нужно %d)." % cost
	gold -= cost
	lvl += 1
	building_levels[building_id] = lvl
	_apply_building_effect(def, lvl)
	_recalc_guild_level()
	add_notification("Улучшено: %s → ур.%d (−%d зол.)" % [str(def.get("name", building_id)), lvl, cost])
	emit_signal("state_changed")
	return ""


func _apply_building_effect(def: Dictionary, lvl: int) -> void:
	var effect: String = str(def.get("effect", "none"))
	var per: int = int(def.get("effect_per_level", 0))
	match effect:
		"roster_slots":
			roster_slots = int(balance.get("roster_start_slots", 10)) + lvl * per
		"food":
			food += per
		"fame":
			fame += per
		"tavern":
			tavern_bonus = lvl * per
		"hospital":
			hospital_bonus = lvl * per
		"mana":
			mana_crystals += per
		"income":
			gold += per
		_:
			pass


func _recalc_guild_level() -> void:
	var total := 0
	for k in building_levels.keys():
		total += int(building_levels[k])
	guild_level = 1 + int(total / 3)


func get_building_defs() -> Array:
	return buildings_data.get("buildings", [])


func refresh_staff_candidates() -> void:
	staff_candidates.clear()
	var roles := [
		["healer", "Лекарь", "Медицина", "Сокращает восстановление героев"],
		["administrator", "Администратор гильдии", "Организация", "Формирует и отправляет отряды"],
		["treasurer", "Казначей", "Финансы", "Контролирует расходы и зарплаты"],
		["scholar", "Учёный", "Магические знания", "Работает в лаборатории и архиве"],
		["trainer", "Мастер-наставник", "Обучение", "Проводит тренировки на арене"],
		["blacksmith", "Кузнец", "Крафт", "Автоматизирует кузницу"],
		["alchemist", "Алхимик", "Алхимия", "Создаёт зелья и реагенты"],
	]
	for role in roles:
		var skill := randi_range(5, 18)
		staff_candidates.append({
			"id": "staff_%s_%d" % [role[0], Time.get_ticks_msec() + staff_candidates.size()],
			"role": role[0], "class_name": role[1], "skill_name": role[2],
			"skill": skill, "description": role[3], "wage": 8 + skill,
		})


func has_staff_role(role: String) -> bool:
	for member in staff_members:
		if typeof(member) == TYPE_DICTIONARY and str(member.get("role", "")) == role:
			return true
	return false


func hire_staff_candidate(index: int) -> String:
	if index < 0 or index >= staff_candidates.size():
		return "Кандидат не найден."
	var candidate: Dictionary = staff_candidates[index]
	var cost := 50 + int(candidate.get("skill", 5)) * 5
	if gold < cost:
		return "Недостаточно золота для найма сотрудника (нужно %d)." % cost
	gold -= cost
	staff_members.append(candidate.duplicate(true))
	staff_candidates.remove_at(index)
	npc_staff = staff_members.size()
	staff_working = debt == 0
	add_notification("Нанят сотрудник: %s · %s %d." % [
		str(candidate.get("class_name", "Сотрудник")), str(candidate.get("skill_name", "Навык")), int(candidate.get("skill", 0)),
	])
	emit_signal("state_changed")
	return ""


func dismiss_staff_member(index: int = -1) -> String:
	if staff_members.is_empty():
		return "В гильдии нет сотрудников."
	var actual_index := staff_members.size() - 1 if index < 0 else index
	if actual_index < 0 or actual_index >= staff_members.size():
		return "Сотрудник не найден."
	var former: Dictionary = staff_members[actual_index]
	staff_members.remove_at(actual_index)
	npc_staff = staff_members.size()
	add_notification("%s покинул гильдию." % str(former.get("class_name", "Сотрудник")))
	emit_signal("state_changed")
	return ""


func run_facility_action(building_id: String) -> String:
	if get_building_level(building_id) <= 0:
		return "Сначала постройте или улучшите это помещение."
	match building_id:
		"forge":
			if not has_staff_role("blacksmith"):
				return "Для кузницы требуется Кузнец."
			if gold < 35:
				return "Для заказа в кузнице нужно 35 золота."
			gold -= 35
			fame += 2
			add_notification("Кузница завершила заказ снаряжения. Слава +2.")
		"laboratory":
			if not has_staff_role("scholar"):
				return "Для лаборатории требуется Учёный."
			if mana_crystals < 2:
				return "Для исследования нужно 2 кристалла маны."
			mana_crystals -= 2
			fame += 3
			add_notification("Магическое исследование завершено. Слава +3.")
		"library":
			if not has_staff_role("scholar"):
				return "Для архива требуется Учёный."
			if gold < 20:
				return "Для работы архива нужно 20 золота."
			gold -= 20
			fame += 1
			add_notification("Архив восстановил новую хронику. Слава +1.")
		"arena":
			if not has_staff_role("trainer"):
				return "Для тренировок требуется Мастер-наставник."
			var trainee: HeroData = null
			for hero in heroes:
				if hero is HeroData and not hero.is_guildmaster and hero.status == HeroData.Status.AVAILABLE:
					trainee = hero
					break
			if trainee == null:
				return "Нет свободного героя для тренировки."
			if gold < 25:
				return "Тренировка стоит 25 золота."
			gold -= 25
			trainee.add_xp(20)
			add_notification("%s завершил тренировку и получил 20 опыта." % trainee.display_name())
		_:
			return "Для этого помещения нет доступного действия."
	emit_signal("state_changed")
	return ""


func assignment_authority() -> String:
	return "Администратор гильдии" if has_staff_role("administrator") else "Гильдмастер"


func process_autonomous_quest_choices() -> void:
	for hero in heroes:
		if not (hero is HeroData) or hero.is_guildmaster or hero.status != HeroData.Status.AVAILABLE:
			continue
		if randf() > 0.28:
			continue
		var best_quest: QuestData = null
		var best_chance := 0.0
		for quest in board_quests:
			if not (quest is QuestData) or quest.taken:
				continue
			var probe := PartyData.new()
			probe.member_ids = PackedStringArray([hero.id])
			var chance := QuestSimulator.estimate_success(probe, quest)
			if chance > best_chance:
				best_chance = chance
				best_quest = quest
		if best_quest == null or best_chance < 0.52:
			continue
		var solo := PartyData.new()
		solo.id = "p_%d" % _next_party_num
		_next_party_num += 1
		solo.party_name = "%s · самостоятельный выход" % hero.hero_name
		solo.member_ids = PackedStringArray([hero.id])
		solo.on_mission = true
		solo.assigned_quest_id = best_quest.id
		solo.days_remaining = best_quest.duration_days
		parties.append(solo)
		best_quest.taken = true
		hero.status = HeroData.Status.ON_QUEST
		add_notification("%s самостоятельно выбрал задание «%s» (оценка шанса %d%%)." % [
			hero.display_name(), best_quest.quest_name, int(best_chance * 100.0),
		])
		break
	emit_signal("state_changed")


func trade_resource(action: String) -> String:
	match action:
		"buy_food":
			if gold < 20:
				return "Недостаточно золота."
			gold -= 20
			food += 10
			add_notification("Куплено 10 припасов за 20 золота.")
		"sell_mana":
			if mana_crystals < 1:
				return "Нет кристаллов маны для продажи."
			mana_crystals -= 1
			gold += 30
			add_notification("Продан кристалл маны за 30 золота.")
		_:
			return "Неизвестная торговая операция."
	emit_signal("state_changed")
	return ""


func hire_recruit(index: int) -> String:
	if index < 0 or index >= tavern_recruits.size():
		return "Нет такого кандидата."
	if not can_hire():
		return "Нет свободных слотов в гильд-холле."
	var hero: HeroData = tavern_recruits[index]
	var cost: int = HeroGenerator.hire_cost(hero)
	if gold < cost:
		return "Недостаточно золота (нужно %d)." % cost
	gold -= cost
	hero.known_level = 5
	hero.history.append("День %d — вступил в гильдию «%s»." % [TimeSystem.day, guild_name])
	heroes.append(hero)
	tavern_recruits.remove_at(index)
	add_notification("Нанят: %s (%s), ранг %s." % [hero.hero_name, hero.class_name_ru(), hero.rank])
	emit_signal("state_changed")
	return ""


func dismiss_hero(hero_id: String) -> String:
	var hero := get_hero(hero_id)
	if hero == null:
		return "Герой не найден."
	if hero.is_guildmaster:
		return "Гильдмастера нельзя уволить."
	if hero.status != HeroData.Status.AVAILABLE:
		return "Нельзя уволить героя, пока он занят или ранен."
	for party in parties:
		if party is PartyData and party.member_ids.has(hero_id):
			return "Сначала исключите героя из отряда."
	heroes.erase(hero)
	add_notification("%s покинул гильдию." % hero.display_name())
	emit_signal("state_changed")
	return ""


func promotion_info(hero: HeroData) -> Dictionary:
	var ranks := ["E", "D", "C", "B", "A"]
	var requirements := {"E": 10, "D": 20, "C": 30, "B": 40}
	var costs := {"E": 2, "D": 5, "C": 10, "B": 20}
	var index := ranks.find(hero.rank)
	if index < 0 or index >= ranks.size() - 1:
		return {"available": false, "next": "", "level": 0, "cost": 0}
	var required_level := int(requirements.get(hero.rank, 999))
	return {
		"available": hero.level >= required_level,
		"next": ranks[index + 1],
		"level": required_level,
		"cost": int(costs.get(hero.rank, 0)),
	}


func promote_hero(hero_id: String) -> String:
	var hero := get_hero(hero_id)
	if hero == null:
		return "Герой не найден."
	var info := promotion_info(hero)
	if not bool(info.get("available", false)):
		return "Герой ещё не готов к повышению."
	var cost := int(info.get("cost", 0))
	if fame < cost:
		return "Для повышения нужно %d славы." % cost
	var previous := hero.rank
	fame -= cost
	hero.rank = str(info.get("next", hero.rank))
	hero.history.append("День %d — повышен с ранга %s до %s." % [TimeSystem.day, previous, hero.rank])
	add_notification("%s повышен до ранга %s." % [hero.display_name(), hero.rank])
	emit_signal("state_changed")
	return ""


func toggle_hero_favorite(hero_id: String) -> String:
	var hero := get_hero(hero_id)
	if hero == null:
		return "Герой не найден."
	hero.is_favorite = not hero.is_favorite
	emit_signal("state_changed")
	return ""


func create_party(party_name: String, member_ids: PackedStringArray, as_gm_party: bool) -> String:
	var min_s: int = int(balance.get("party_min_size", 2))
	var max_s: int = int(balance.get("party_max_size", 6))
	if member_ids.size() < min_s or member_ids.size() > max_s:
		return "Размер отряда: %d–%d." % [min_s, max_s]

	var has_gm := false
	for id in member_ids:
		var h := get_hero(id)
		if h == null:
			return "Герой не найден."
		if h.status != HeroData.Status.AVAILABLE:
			return "%s недоступен." % h.display_name()
		if h.is_guildmaster:
			has_gm = true

	if has_gm and not as_gm_party:
		return "ГМ не вступает в чужой отряд. Создайте отряд ГМ."
	if as_gm_party and not has_gm:
		return "Отряд ГМ должен включать Гильдмастера."

	for id in member_ids:
		var h2 := get_hero(id)
		for p in parties:
			if p is PartyData and not p.on_mission and p.member_ids.has(id):
				return "%s уже в отряде «%s». Сначала расформируйте." % [h2.display_name(), p.party_name]

	## Remove members from idle parties
	for p in parties:
		if p is PartyData and not p.on_mission:
			var kept := PackedStringArray()
			for mid in p.member_ids:
				if not member_ids.has(mid):
					kept.append(mid)
			p.member_ids = kept

	var party := PartyData.new()
	party.id = "p_%d" % _next_party_num
	_next_party_num += 1
	party.party_name = party_name if party_name != "" else ("Отряд %d" % _next_party_num)
	party.member_ids = member_ids.duplicate()
	party.is_gm_party = as_gm_party and has_gm
	parties.append(party)
	## Cleanup empty parties
	parties = parties.filter(func(p): return p is PartyData and p.member_ids.size() > 0)
	add_notification("Создан отряд «%s» (%d чел.)." % [party.party_name, party.size()])
	emit_signal("state_changed")
	return ""


func disband_party(party_id: String) -> void:
	for i in parties.size():
		var p: PartyData = parties[i]
		if p.id == party_id and not p.on_mission:
			parties.remove_at(i)
			emit_signal("state_changed")
			return


func assign_quest(party_id: String, quest_id: String) -> String:
	var party: PartyData = null
	var quest: QuestData = null
	for p in parties:
		if p is PartyData and p.id == party_id:
			party = p
			break
	for q in board_quests:
		if q is QuestData and q.id == quest_id:
			quest = q
			break
	if party == null:
		return "Отряд не найден."
	if quest == null:
		return "Квест не найден."
	if party.on_mission:
		return "Отряд уже на задании."
	if quest.taken:
		return "Квест уже взят."
	if party.member_ids.size() < int(balance.get("party_min_size", 2)):
		return "В отряде слишком мало героев."

	for id in party.member_ids:
		var h := get_hero(id)
		if h == null or h.status != HeroData.Status.AVAILABLE:
			return "Не все члены отряда доступны."

	for id in party.member_ids:
		var h := get_hero(id)
		h.status = HeroData.Status.ON_QUEST

	party.on_mission = true
	party.assigned_quest_id = quest.id
	party.days_remaining = quest.duration_days
	quest.taken = true
	add_notification("«%s» отправлен на «%s» (%d дн.)." % [party.party_name, quest.quest_name, quest.duration_days])
	emit_signal("state_changed")
	return ""


func process_missions_day() -> void:
	var finished: Array = []
	for p in parties:
		if p is PartyData and p.on_mission:
			p.days_remaining -= 1
			if p.days_remaining <= 0:
				finished.append(p)

	for p in finished:
		var quest: QuestData = null
		for q in board_quests:
			if q is QuestData and q.id == p.assigned_quest_id:
				quest = q
				break
		if quest == null:
			## Reconstruct minimal quest if board refreshed
			quest = QuestData.new()
			quest.quest_name = "Задание"
			quest.quest_type = "combat"
			quest.difficulty = 1
			quest.gold_reward = 50
			quest.fame_reward = 1
		var report: Dictionary = QuestSimulator.resolve(p, quest)
		last_report = report
		add_notification(str(report.get("text", "Отчёт о квесте.")))
		emit_signal("quest_resolved", report)
		if report.get("gm_dead", false):
			is_game_over = true
			emit_signal("game_over", "Гильдмастер погиб. Игра окончена.")
			return

	## Remove dead from roster display but keep for journal? Remove dead non-GM
	heroes = heroes.filter(func(h): return h is HeroData and (h.status != HeroData.Status.DEAD or h.is_guildmaster))


func to_save_dict() -> Dictionary:
	return {
		"guild_name": guild_name,
		"guild_level": guild_level,
		"guild_crest_emblem": guild_crest_emblem,
		"guild_crest_color": guild_crest_color,
		"guild_crest_pattern": guild_crest_pattern,
		"guild_crest_shield": guild_crest_shield,
		"guild_crest_secondary_color": guild_crest_secondary_color,
		"guild_crest_charge_color": guild_crest_charge_color,
		"guild_crest_border": guild_crest_border,
		"guild_crest_seed": guild_crest_seed,
		"guild_origin": guild_origin,
		"intro_story": intro_story,
		"gold": gold,
		"mana_crystals": mana_crystals,
		"fame": fame,
		"food": food,
		"debt": debt,
		"roster_slots": roster_slots,
		"npc_staff": npc_staff,
		"staff_working": staff_working,
		"staff_members": staff_members.duplicate(true),
		"staff_candidates": staff_candidates.duplicate(true),
		"building_levels": building_levels.duplicate(),
		"tavern_bonus": tavern_bonus,
		"hospital_bonus": hospital_bonus,
		"heroes": heroes.map(func(h): return h.to_dict()),
		"parties": parties.map(func(p): return p.to_dict()),
		"board_quests": board_quests.map(func(q): return q.to_dict()),
		"tavern_recruits": tavern_recruits.map(func(h): return h.to_dict()),
		"notifications": Array(notifications),
		"last_report": last_report,
		"is_game_over": is_game_over,
		"tutorial_seen": tutorial_seen,
		"_next_party_num": _next_party_num,
		"_quest_seq": _quest_seq,
		"time": TimeSystem.to_dict(),
	}


func load_from_dict(d: Dictionary) -> void:
	guild_name = str(d.get("guild_name", "Гильдия"))
	guild_level = int(d.get("guild_level", 1))
	guild_crest_emblem = str(d.get("guild_crest_emblem", "star"))
	guild_crest_color = str(d.get("guild_crest_color", "crimson"))
	guild_crest_pattern = str(d.get("guild_crest_pattern", "solid"))
	guild_crest_shield = str(d.get("guild_crest_shield", "heater"))
	guild_crest_secondary_color = str(d.get("guild_crest_secondary_color", "ivory"))
	guild_crest_charge_color = str(d.get("guild_crest_charge_color", "gold"))
	guild_crest_border = str(d.get("guild_crest_border", "gold_simple"))
	guild_crest_seed = int(d.get("guild_crest_seed", 0))
	guild_origin = str(d.get("guild_origin", "Свободная гильдия"))
	intro_story = str(d.get("intro_story", ""))
	gold = int(d.get("gold", 0))
	mana_crystals = int(d.get("mana_crystals", 0))
	fame = int(d.get("fame", 0))
	food = int(d.get("food", 0))
	debt = int(d.get("debt", 0))
	roster_slots = int(d.get("roster_slots", 10))
	npc_staff = int(d.get("npc_staff", 1))
	staff_working = bool(d.get("staff_working", true))
	staff_members = d.get("staff_members", []).duplicate(true)
	staff_candidates = d.get("staff_candidates", []).duplicate(true)
	if staff_candidates.is_empty():
		refresh_staff_candidates()
	npc_staff = staff_members.size() if d.has("staff_members") else npc_staff
	building_levels = d.get("building_levels", {}).duplicate()
	tavern_bonus = int(d.get("tavern_bonus", 0))
	hospital_bonus = int(d.get("hospital_bonus", 0))
	heroes.clear()
	for hd in d.get("heroes", []):
		heroes.append(HeroData.from_dict(hd))
	parties.clear()
	for pd in d.get("parties", []):
		parties.append(PartyData.from_dict(pd))
	board_quests.clear()
	for qd in d.get("board_quests", []):
		board_quests.append(QuestData.from_dict(qd))
	tavern_recruits.clear()
	for hd in d.get("tavern_recruits", []):
		tavern_recruits.append(HeroData.from_dict(hd))
	notifications = PackedStringArray(d.get("notifications", []))
	last_report = d.get("last_report", {})
	is_game_over = bool(d.get("is_game_over", false))
	tutorial_seen = bool(d.get("tutorial_seen", false))
	_next_party_num = int(d.get("_next_party_num", 1))
	_quest_seq = int(d.get("_quest_seq", 1))
	TimeSystem.load_from_dict(d.get("time", {}))
	emit_signal("state_changed")
