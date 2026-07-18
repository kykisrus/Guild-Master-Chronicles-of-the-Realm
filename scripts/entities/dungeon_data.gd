class_name DungeonData
extends RefCounted

var dungeon_id: String = ""
var dungeon_name: String = ""
var seed_value: int = 0
var difficulty: int = 1
var floors: int = 1
var biome: String = "ancient_ruins"
var rooms: Array[Dictionary] = []
var current_room_id: String = "room_0"
var explored_rooms: PackedStringArray = PackedStringArray()
var discovered_rooms: PackedStringArray = PackedStringArray()
var completed: bool = false


func room_by_id(room_id: String) -> Dictionary:
	for room in rooms:
		if str(room.get("id", "")) == room_id:
			return room
	return {}


func current_room() -> Dictionary:
	return room_by_id(current_room_id)


func reveal(room_id: String, explored: bool = false) -> void:
	if room_id not in discovered_rooms:
		discovered_rooms.append(room_id)
	if explored and room_id not in explored_rooms:
		explored_rooms.append(room_id)
	var room := room_by_id(room_id)
	for next_id in room.get("next", []):
		if str(next_id) not in discovered_rooms:
			discovered_rooms.append(str(next_id))

