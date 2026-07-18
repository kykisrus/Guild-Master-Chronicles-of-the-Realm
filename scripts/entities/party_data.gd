class_name PartyData
extends RefCounted

var id: String = ""
var party_name: String = ""
var member_ids: PackedStringArray = PackedStringArray()
var is_gm_party: bool = false
var assigned_quest_id: String = ""
var days_remaining: int = 0
var on_mission: bool = false


func size() -> int:
	return member_ids.size()


func to_dict() -> Dictionary:
	return {
		"id": id,
		"party_name": party_name,
		"member_ids": Array(member_ids),
		"is_gm_party": is_gm_party,
		"assigned_quest_id": assigned_quest_id,
		"days_remaining": days_remaining,
		"on_mission": on_mission,
	}


static func from_dict(d: Dictionary) -> PartyData:
	var p := PartyData.new()
	p.id = str(d.get("id", ""))
	p.party_name = str(d.get("party_name", ""))
	p.member_ids = PackedStringArray(d.get("member_ids", []))
	p.is_gm_party = bool(d.get("is_gm_party", false))
	p.assigned_quest_id = str(d.get("assigned_quest_id", ""))
	p.days_remaining = int(d.get("days_remaining", 0))
	p.on_mission = bool(d.get("on_mission", false))
	return p
