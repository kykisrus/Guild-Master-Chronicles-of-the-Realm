extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CREDITS_MD := "res://docs/credits/THIRD_PARTY_CREDITS.md"

@onready var title_label: Label = %Title
@onready var credits_label: Label = %CreditsLabel
@onready var btn_back: Button = %BtnBack


func _ready() -> void:
	theme = TinySwordsThemeFactory.build()
	MusicController.enter_menu_context()
	title_label.text = tr("credits.title")
	btn_back.text = tr("menu.back")
	btn_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	credits_label.text = _load_credits_text()


func _load_credits_text() -> String:
	var f := FileAccess.open(CREDITS_MD, FileAccess.READ)
	if f == null:
		return _fallback_credits()
	return f.get_as_text()


func _fallback_credits() -> String:
	return "\n".join([
		"Guild Master: Chronicles of the Realm",
		"Автор: Kuk Bakharev / AMS",
		"Движок: Godot Engine",
		"UI: Tiny GUI Pack (Vryell)",
		"Шрифт: Pix Cyrillic (zedseven / lotva, OFL)",
	])
