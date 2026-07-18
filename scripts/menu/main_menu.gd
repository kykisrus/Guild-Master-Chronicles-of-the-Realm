extends Control

const LOAD_SCENE := "res://scenes/menu/load_menu.tscn"
const SETTINGS_SCENE := "res://scenes/menu/settings_menu.tscn"
const CREDITS_SCENE := "res://scenes/menu/credits_menu.tscn"
const INTRO_SCENE := "res://scenes/intro/intro_field.tscn"

@onready var title_label: Label = %TitleLabel
@onready var btn_new: Button = %BtnNew
@onready var btn_load: Button = %BtnLoad
@onready var btn_settings: Button = %BtnSettings
@onready var btn_credits: Button = %BtnCredits
@onready var btn_exit: Button = %BtnExit

var _info: AcceptDialog


func _ready() -> void:
	theme = TinyThemeFactory.build()
	MusicController.enter_menu_context()
	_refresh_texts()
	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_settings.pressed.connect(_on_settings)
	btn_credits.pressed.connect(_on_credits)
	btn_exit.pressed.connect(_on_exit)
	btn_new.grab_focus()


func _refresh_texts() -> void:
	title_label.text = "Guild Master"
	btn_new.text = tr("menu.new_game")
	btn_load.text = tr("menu.load")
	btn_settings.text = tr("menu.settings")
	btn_credits.text = tr("menu.credits")
	btn_exit.text = tr("menu.exit")


func _on_new() -> void:
	MusicController.leave_menu_context()
	get_tree().change_scene_to_file(INTRO_SCENE)


func _on_load() -> void:
	get_tree().change_scene_to_file(LOAD_SCENE)


func _on_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_credits() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_exit() -> void:
	get_tree().quit()


func _show_info(title_text: String, body: String) -> void:
	if _info == null:
		_info = AcceptDialog.new()
		_info.theme = theme
		add_child(_info)
	_info.title = title_text
	_info.dialog_text = body
	_info.ok_button_text = tr("menu.ok")
	_info.popup_centered()
