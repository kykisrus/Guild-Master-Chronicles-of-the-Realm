extends Node

const SLOT_COUNT := 3


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false


func slot_metadata(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func latest_save_slot() -> int:
	var latest_slot := 0
	var latest_time := ""
	for slot in range(1, SLOT_COUNT + 1):
		var data := slot_metadata(slot)
		if data.is_empty():
			continue
		var saved_at := str(data.get("saved_at", ""))
		if latest_slot == 0 or saved_at > latest_time:
			latest_slot = slot
			latest_time = saved_at
	return latest_slot


func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: int) -> String:
	if slot < 1 or slot > SLOT_COUNT:
		return "Неверный слот."
	var data: Dictionary = GameState.to_save_dict()
	data["saved_at"] = Time.get_datetime_string_from_system()
	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		return "Не удалось открыть файл сохранения."
	f.store_string(json)
	GameState.add_notification("Игра сохранена в слот %d." % slot)
	return ""


func load_game(slot: int) -> String:
	if slot < 1 or slot > SLOT_COUNT:
		return "Неверный слот."
	if not has_save(slot):
		return "Слот %d пуст." % slot
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return "Не удалось прочитать сохранение."
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Повреждённый файл сохранения."
	GameState.load_from_dict(parsed)
	GameState.add_notification("Загружен слот %d." % slot)
	return ""


func slot_info(slot: int) -> String:
	if not has_save(slot):
		return "Слот %d — пусто" % slot
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return "Слот %d — ошибка" % slot
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Слот %d — повреждён" % slot
	var d: Dictionary = parsed
	return "Слот %d — %s | %s | золото %d" % [
		slot,
		str(d.get("guild_name", "?")),
		str(d.get("time", {}).get("year", "?")) + "г. д." + str(d.get("time", {}).get("day", "?")),
		int(d.get("gold", 0)),
	]
