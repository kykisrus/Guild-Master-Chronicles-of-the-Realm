class_name QuestData
extends RefCounted

var id: String = ""
var template_id: String = ""
var quest_name: String = ""
var quest_type: String = "combat"
var difficulty: int = 1
var duration_days: int = 3
var gold_reward: int = 50
var fame_reward: int = 1
var mana_chance: float = 0.1
var taken: bool = false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"template_id": template_id,
		"quest_name": quest_name,
		"quest_type": quest_type,
		"difficulty": difficulty,
		"duration_days": duration_days,
		"gold_reward": gold_reward,
		"fame_reward": fame_reward,
		"mana_chance": mana_chance,
		"taken": taken,
	}


static func from_dict(d: Dictionary) -> QuestData:
	var q := QuestData.new()
	q.id = str(d.get("id", ""))
	q.template_id = str(d.get("template_id", ""))
	q.quest_name = str(d.get("quest_name", ""))
	q.quest_type = str(d.get("quest_type", "combat"))
	q.difficulty = int(d.get("difficulty", 1))
	q.duration_days = int(d.get("duration_days", 3))
	q.gold_reward = int(d.get("gold_reward", 50))
	q.fame_reward = int(d.get("fame_reward", 1))
	q.mana_chance = float(d.get("mana_chance", 0.1))
	q.taken = bool(d.get("taken", false))
	return q
