class_name DungeonGenerator
extends RefCounted

const ROOM_TYPES := ["combat", "event", "trap", "rest", "treasure", "shrine", "resource"]


static func generate(seed_value: int, difficulty: int = 1, biome: String = "ancient_ruins") -> DungeonData:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var dungeon := DungeonData.new()
	dungeon.seed_value = seed_value
	dungeon.dungeon_id = "dungeon_%d" % absi(seed_value)
	dungeon.dungeon_name = _dungeon_name(rng, biome)
	dungeon.difficulty = difficulty
	dungeon.floors = 1 + difficulty / 2
	dungeon.biome = biome

	var main_length := rng.randi_range(7, 9)
	for i in main_length:
		var room_type: String = "entrance" if i == 0 else "boss" if i == main_length - 1 else str(ROOM_TYPES[rng.randi_range(0, ROOM_TYPES.size() - 1)])
		dungeon.rooms.append(_room("room_%d" % i, room_type, Vector2i(i, 2), difficulty, rng))
	for i in range(main_length - 1):
		dungeon.rooms[i]["next"].append("room_%d" % (i + 1))

	var branch_count := rng.randi_range(2, 3)
	var branch_serial := 0
	for branch in branch_count:
		var source_index := rng.randi_range(1, main_length - 3)
		var direction := -1 if branch % 2 == 0 else 1
		var length := rng.randi_range(1, 2)
		var previous_id := "room_%d" % source_index
		for step in length:
			var branch_id := "branch_%d" % branch_serial
			branch_serial += 1
			var room_type: String = "treasure" if step == length - 1 else str(ROOM_TYPES[rng.randi_range(0, ROOM_TYPES.size() - 1)])
			var room := _room(branch_id, room_type, Vector2i(source_index + step + 1, 2 + direction * (step + 1)), difficulty, rng)
			dungeon.rooms.append(room)
			dungeon.room_by_id(previous_id)["next"].append(branch_id)
			previous_id = branch_id

	dungeon.current_room_id = "room_0"
	dungeon.reveal("room_0", true)
	return dungeon


static func _room(id: String, type: String, position: Vector2i, difficulty: int, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"id": id,
		"type": type,
		"position": position,
		"next": [],
		"danger": 0 if type in ["entrance", "rest", "treasure"] else difficulty + rng.randi_range(0, 2),
		"reward": 0 if type in ["entrance", "trap"] else rng.randi_range(8, 22) * difficulty,
		"monster": _monster(type, difficulty, rng),
	}


static func _monster(type: String, difficulty: int, rng: RandomNumberGenerator) -> Dictionary:
	if type not in ["combat", "elite_combat", "boss"]:
		return {}
	var names := ["Гоблин-налётчик", "Костяной страж", "Пещерный зверь", "Осквернённый рыцарь"]
	return {
		"id": "monster_%d" % rng.randi(),
		"name": "Хранитель глубин" if type == "boss" else names[rng.randi_range(0, names.size() - 1)],
		"level": difficulty + rng.randi_range(1, 3),
		"combat_power": difficulty * 8 + rng.randi_range(3, 12),
		"traits": ["melee", "guardian"] if type == "boss" else ["melee"],
	}


static func _dungeon_name(rng: RandomNumberGenerator, biome: String) -> String:
	var first := ["Затонувшие", "Пепельные", "Забытые", "Безмолвные"]
	var last := "руины" if biome == "ancient_ruins" else "катакомбы"
	return "%s %s" % [first[rng.randi_range(0, first.size() - 1)], last]
