extends Node

const SLOT_COUNT := 3
## Stage 3 campaign schema.
const CURRENT_SAVE_VERSION := 1


enum SlotStatus {
	EMPTY,
	AVAILABLE,
	INCOMPATIBLE,
	CORRUPTED,
}


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false


func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func get_slot_status(slot: int) -> SlotStatus:
	if slot < 1 or slot > SLOT_COUNT:
		return SlotStatus.EMPTY
	if not has_save(slot):
		return SlotStatus.EMPTY
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return SlotStatus.CORRUPTED
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return SlotStatus.CORRUPTED
	var data: Dictionary = parsed
	if not data.has("save_version"):
		return SlotStatus.INCOMPATIBLE
	if int(data.get("save_version", -1)) != CURRENT_SAVE_VERSION:
		return SlotStatus.INCOMPATIBLE
	# Stage 3 campaign must have guild block
	if not data.has("guild") and not data.has("guild_name"):
		return SlotStatus.INCOMPATIBLE
	return SlotStatus.AVAILABLE


func slot_status_key(slot: int) -> String:
	match get_slot_status(slot):
		SlotStatus.EMPTY:
			return "save.empty"
		SlotStatus.AVAILABLE:
			return "save.available"
		SlotStatus.INCOMPATIBLE:
			return "save.incompatible"
		SlotStatus.CORRUPTED:
			return "save.corrupted"
		_:
			return "save.empty"


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
		if get_slot_status(slot) != SlotStatus.AVAILABLE:
			continue
		var data := slot_metadata(slot)
		if data.is_empty():
			continue
		var saved_at := str(data.get("saved_at", ""))
		if latest_slot == 0 or saved_at > latest_time:
			latest_slot = slot
			latest_time = saved_at
	return latest_slot


func save_campaign(slot: int) -> String:
	if slot < 1 or slot > SLOT_COUNT:
		return "Неверный слот."
	var data: Dictionary = CampaignState.to_save_dict()
	data["save_version"] = CURRENT_SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		return "Не удалось открыть файл сохранения."
	f.store_string(json)
	return ""


func load_campaign(slot: int) -> String:
	if slot < 1 or slot > SLOT_COUNT:
		return "Неверный слот."
	match get_slot_status(slot):
		SlotStatus.EMPTY:
			return "Слот %d пуст." % slot
		SlotStatus.CORRUPTED:
			return "Повреждённый файл сохранения."
		SlotStatus.INCOMPATIBLE:
			return "Несовместимая версия сохранения."
		_:
			pass
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return "Не удалось прочитать сохранение."
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Повреждённый файл сохранения."
	CampaignState.load_from_dict(parsed)
	return ""


## Legacy wrappers (Stage 1 prototype) — prefer save_campaign / load_campaign.
func save_game(slot: int) -> String:
	return save_campaign(slot)


func load_game(slot: int) -> String:
	return load_campaign(slot)


func delete_save(slot: int) -> String:
	if slot < 1 or slot > SLOT_COUNT:
		return "Неверный слот."
	if not has_save(slot):
		return "Слот %d пуст." % slot
	var abs_path := ProjectSettings.globalize_path(slot_path(slot))
	var err := DirAccess.remove_absolute(abs_path)
	if err != OK:
		return "Не удалось удалить сохранение (код %d)." % err
	return ""


func slot_info(slot: int) -> String:
	match get_slot_status(slot):
		SlotStatus.EMPTY:
			return "Слот %d — пусто" % slot
		SlotStatus.CORRUPTED:
			return "Слот %d — повреждён" % slot
		SlotStatus.INCOMPATIBLE:
			return "Слот %d — несовместим" % slot
		_:
			pass
	var d := slot_metadata(slot)
	var gname := str(d.get("guild_name", ""))
	if gname.is_empty() and typeof(d.get("guild", null)) == TYPE_DICTIONARY:
		gname = str(d["guild"].get("name", "?"))
	if gname.is_empty():
		gname = "?"
	return "Слот %d — %s | %s" % [slot, gname, str(d.get("saved_at", "?"))]


func first_writable_slot() -> int:
	for slot in range(1, SLOT_COUNT + 1):
		if get_slot_status(slot) == SlotStatus.EMPTY:
			return slot
	return 1
