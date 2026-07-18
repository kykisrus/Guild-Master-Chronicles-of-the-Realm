class_name HeroData
extends RefCounted

enum Alignment { LAWFUL_GOOD, NEUTRAL_GOOD, CHAOTIC_GOOD, LAWFUL_NEUTRAL, TRUE_NEUTRAL, CHAOTIC_NEUTRAL, LAWFUL_EVIL, NEUTRAL_EVIL, CHAOTIC_EVIL }
enum Status { AVAILABLE, ON_QUEST, HOSPITAL, DEAD }

const RANK_TABLE := {
	"E": {"min_level": 1, "max_level": 9},
	"D": {"min_level": 10, "max_level": 19},
	"C": {"min_level": 20, "max_level": 29},
	"B": {"min_level": 30, "max_level": 39},
	"A": {"min_level": 40, "max_level": 54},
}

var id: String = ""
var hero_name: String = ""
var last_name: String = ""
var nickname: String = ""
var gender: String = "male"
var origin: String = "Свободные Земли"
var age: int = 24
var home_kingdom: String = "Свободные Земли"
var class_id: String = "warrior"
var class_display: String = "Воин"
var is_guildmaster: bool = false
var level: int = 1
var xp: int = 0
var rank: String = "E"
var alignment: int = Alignment.TRUE_NEUTRAL
var status: int = Status.AVAILABLE

## Guildmaster-only management profile. Kept on HeroData so it follows the
## founder through normal save/load and remains available to later systems.
var primary_management_stats: Dictionary = {
	"diplomacy": 10, "charisma": 10, "influence": 10, "leadership": 10,
}
var management_skills: Dictionary = {
	"strategy": 10, "tactics": 10, "finance": 10, "organization": 10,
	"trade": 10, "psychology": 10, "staff_management": 10, "crafting": 10,
	"arcane_knowledge": 10, "warfare": 10, "scouting": 10, "logistics": 10,
	"training": 10, "reputation": 10, "stress_resistance": 10,
}
var temperament: String = "Флегматик"
var rare_gift: String = "Взгляд Гильдмастера"
var weakness: String = "Склонность к риску"
var portrait_id: String = "gm_portrait_01"
var known_level: int = 5
var potential: int = 3
var biography_short: String = ""
var personal_goal: String = ""
var history: PackedStringArray = PackedStringArray()
var is_favorite: bool = false

var str_stat: int = 8
var dex_stat: int = 8
var con_stat: int = 8
var int_stat: int = 8
var wis_stat: int = 8
var cha_stat: int = 8

var morale: int = 70
var loyalty: int = 70
var hospital_days: int = 0
var fatigue: int = 0

var weapon_proficiencies: Dictionary = {
	"one_handed": 0, "two_handed": 0, "polearms": 0, "light_blades": 0,
	"bows": 0, "crossbows": 0, "throwing": 0, "unarmed": 0,
}
var magic_schools: Dictionary = {
	"fire": 0, "ice": 0, "lightning": 0, "earth": 0, "light": 0,
	"dark": 0, "illusion": 0, "summoning": 0, "arcana": 0,
}
var skills: Dictionary = {
	"athletics": 0, "acrobatics": 0, "stealth": 0, "perception": 0,
	"survival": 0, "medicine": 0, "diplomacy": 0, "intimidation": 0,
	"crafting": 0, "alchemy": 0, "lore": 0,
}

## Preference tags: likes combat / hates combat / likes gathering / likes escort
var likes: PackedStringArray = PackedStringArray()
var dislikes: PackedStringArray = PackedStringArray()

var cohesion_with: Dictionary = {} ## hero_id -> int


func display_name() -> String:
	var full_name := hero_name
	if not last_name.is_empty():
		full_name += " " + last_name
	if not nickname.is_empty():
		full_name += " «%s»" % nickname
	if is_guildmaster:
		return "%s (ГМ)" % full_name
	return full_name


func class_name_ru() -> String:
	if class_display != "":
		return class_display
	return class_id


func get_stat(stat_id: String) -> int:
	match stat_id:
		"str":
			return str_stat
		"dex":
			return dex_stat
		"con":
			return con_stat
		"int":
			return int_stat
		"wis":
			return wis_stat
		"cha":
			return cha_stat
		_:
			return 0


func power_score() -> float:
	var best_weapon := 0
	for value in weapon_proficiencies.values():
		best_weapon = maxi(best_weapon, int(value))
	var best_magic := 0
	for value in magic_schools.values():
		best_magic = maxi(best_magic, int(value))
	return (
		float(str_stat + dex_stat + con_stat + int_stat + wis_stat + cha_stat) / 6.0
		+ float(level)
		+ float(best_weapon) * 0.12
		+ float(best_magic) * 0.1
	)


func max_hp() -> int:
	return 30 + con_stat * 5 + str_stat * 2 + level * 3


func max_mana() -> int:
	return 10 + int_stat * 4 + wis_stat * 3 + level * 2


func physical_defense() -> int:
	return con_stat * 2 + str_stat + level


func magical_defense() -> int:
	return wis_stat * 2 + int_stat + level


func speed_score() -> int:
	return dex_stat * 2 + int(level / 2)


func initiative_score() -> int:
	return dex_stat + wis_stat + int(level / 2)


func critical_chance() -> float:
	return clampf(0.02 + float(dex_stat) * 0.005, 0.02, 0.35)


func add_xp(amount: int) -> void:
	if status == Status.DEAD:
		return
	if is_guildmaster:
		amount = int(round(float(amount) * 1.25))
	xp += amount
	while xp >= xp_to_next() and level < 100:
		xp -= xp_to_next()
		level += 1
		_bump_random_stat()


func xp_to_next() -> int:
	return 40 + level * 15


func _bump_random_stat() -> void:
	var keys := ["str", "dex", "con", "int", "wis", "cha"]
	var pick: String = keys[randi() % keys.size()]
	match pick:
		"str":
			str_stat += 1
		"dex":
			dex_stat += 1
		"con":
			con_stat += 1
		"int":
			int_stat += 1
		"wis":
			wis_stat += 1
		"cha":
			cha_stat += 1


func _update_rank() -> void:
	for r in ["A", "B", "C", "D", "E"]:
		var band: Dictionary = RANK_TABLE[r]
		if level >= int(band["min_level"]) and level <= int(band["max_level"]):
			rank = r
			return
	if level >= 40:
		rank = "A"


func preference_modifier(quest_type: String) -> float:
	var mod := 0.0
	if likes.has(quest_type):
		if quest_type == "combat":
			mod += 0.05
		else:
			mod += 0.08
	if dislikes.has(quest_type):
		if quest_type == "combat" and likes.has("pacifist"):
			mod -= 0.9
		else:
			mod -= 0.1
	if likes.has("pacifist"):
		if quest_type == "combat":
			mod -= 0.9
		else:
			mod += 0.9
	return clampf(mod, -0.95, 0.95)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"hero_name": hero_name,
		"last_name": last_name,
		"nickname": nickname,
		"gender": gender,
		"origin": origin,
		"age": age,
		"home_kingdom": home_kingdom,
		"class_id": class_id,
		"class_display": class_display,
		"is_guildmaster": is_guildmaster,
		"level": level,
		"xp": xp,
		"rank": rank,
		"alignment": alignment,
		"status": status,
		"primary_management_stats": primary_management_stats.duplicate(),
		"management_skills": management_skills.duplicate(),
		"temperament": temperament,
		"rare_gift": rare_gift,
		"weakness": weakness,
		"portrait_id": portrait_id,
		"known_level": known_level,
		"potential": potential,
		"biography_short": biography_short,
		"personal_goal": personal_goal,
		"history": Array(history),
		"is_favorite": is_favorite,
		"str_stat": str_stat,
		"dex_stat": dex_stat,
		"con_stat": con_stat,
		"int_stat": int_stat,
		"wis_stat": wis_stat,
		"cha_stat": cha_stat,
		"morale": morale,
		"loyalty": loyalty,
		"hospital_days": hospital_days,
		"fatigue": fatigue,
		"weapon_proficiencies": weapon_proficiencies.duplicate(),
		"magic_schools": magic_schools.duplicate(),
		"skills": skills.duplicate(),
		"likes": Array(likes),
		"dislikes": Array(dislikes),
		"cohesion_with": cohesion_with.duplicate(),
	}


static func from_dict(d: Dictionary) -> HeroData:
	var h := HeroData.new()
	h.id = str(d.get("id", ""))
	h.hero_name = str(d.get("hero_name", ""))
	h.last_name = str(d.get("last_name", ""))
	h.nickname = str(d.get("nickname", ""))
	h.gender = str(d.get("gender", "male"))
	h.origin = str(d.get("origin", "Свободные Земли"))
	h.age = int(d.get("age", 24))
	h.home_kingdom = str(d.get("home_kingdom", "Свободные Земли"))
	h.class_id = str(d.get("class_id", "warrior"))
	h.class_display = str(d.get("class_display", h.class_id))
	h.is_guildmaster = bool(d.get("is_guildmaster", false))
	h.level = int(d.get("level", 1))
	h.xp = int(d.get("xp", 0))
	h.rank = str(d.get("rank", "E"))
	h.alignment = int(d.get("alignment", Alignment.TRUE_NEUTRAL))
	h.status = int(d.get("status", Status.AVAILABLE))
	h.primary_management_stats = d.get("primary_management_stats", h.primary_management_stats).duplicate()
	h.management_skills = d.get("management_skills", h.management_skills).duplicate()
	h.temperament = str(d.get("temperament", "Флегматик"))
	h.rare_gift = str(d.get("rare_gift", "Взгляд Гильдмастера"))
	h.weakness = str(d.get("weakness", "Склонность к риску"))
	h.portrait_id = str(d.get("portrait_id", "gm_portrait_01"))
	h.known_level = int(d.get("known_level", 5))
	h.potential = int(d.get("potential", 3))
	h.biography_short = str(d.get("biography_short", ""))
	h.personal_goal = str(d.get("personal_goal", ""))
	h.history = PackedStringArray(d.get("history", []))
	h.is_favorite = bool(d.get("is_favorite", false))
	h.str_stat = int(d.get("str_stat", 8))
	h.dex_stat = int(d.get("dex_stat", 8))
	h.con_stat = int(d.get("con_stat", 8))
	h.int_stat = int(d.get("int_stat", 8))
	h.wis_stat = int(d.get("wis_stat", 8))
	h.cha_stat = int(d.get("cha_stat", 8))
	h.morale = int(d.get("morale", 70))
	h.loyalty = int(d.get("loyalty", 70))
	h.hospital_days = int(d.get("hospital_days", 0))
	h.fatigue = int(d.get("fatigue", 0))
	h.weapon_proficiencies = d.get("weapon_proficiencies", h.weapon_proficiencies).duplicate()
	h.magic_schools = d.get("magic_schools", h.magic_schools).duplicate()
	h.skills = d.get("skills", h.skills).duplicate()
	h.likes = PackedStringArray(d.get("likes", []))
	h.dislikes = PackedStringArray(d.get("dislikes", []))
	h.cohesion_with = d.get("cohesion_with", {}).duplicate()
	return h
