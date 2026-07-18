extends Node
## Runtime localization loader for Stage 1 (CSV → TranslationServer).

const CSV_PATH := "res://data/localization/ru.csv"


func _ready() -> void:
	_load_csv()
	TranslationServer.set_locale("ru")


func _load_csv() -> void:
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		push_warning("Localization CSV missing: %s" % CSV_PATH)
		return
	var header := f.get_csv_line()
	if header.size() < 2:
		return
	var locale := header[1].strip_edges()
	var translation := Translation.new()
	translation.locale = locale
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2:
			continue
		var key := row[0].strip_edges()
		if key.is_empty() or key == "keys":
			continue
		translation.add_message(key, row[1])
	TranslationServer.add_translation(translation)
