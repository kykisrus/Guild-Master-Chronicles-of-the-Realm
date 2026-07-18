extends Control
## Guild naming + palette preview + found confirm.

const HUB_SCENE := "res://scenes/guild_hub/guild_hub.tscn"
const GM_FRAMES := "res://resources/sprite_frames/characters/guildmaster.tres"
const PALETTES := ["blue", "red", "black", "yellow", "purple"]

@onready var title: Label = %Title
@onready var name_edit: LineEdit = %GuildName
@onready var palette_box: HBoxContainer = %PaletteBox
@onready var preview_barracks: TextureRect = %PreviewBarracks
@onready var preview_unit: TextureRect = %PreviewUnit
@onready var error_label: Label = %ErrorLabel
@onready var btn_found: Button = %BtnFound
@onready var lbl_name: Label = %LblName
@onready var lbl_palette: Label = %LblPalette
@onready var palette_name: Label = %PaletteName
@onready var panel: PanelContainer = $Center/Panel

var _palette: String = "blue"
var _confirm: ConfirmationDialog


func _ready() -> void:
	theme = TinySwordsThemeFactory.build()
	panel.add_theme_stylebox_override("panel", TinySwordsUi.style_from_sheet(TinySwordsUi.PAPER_SPECIAL, 18, TinySwordsUi.PANEL_MAX_TEX_MARGIN))
	btn_found.add_theme_stylebox_override("normal", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	btn_found.add_theme_stylebox_override("hover", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	btn_found.add_theme_stylebox_override("pressed", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE_PRESSED, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	title.text = tr("guild_creation.title")
	lbl_name.text = tr("guild_creation.name")
	lbl_palette.text = tr("guild_creation.palette")
	btn_found.text = tr("guild_creation.found")
	error_label.text = ""
	name_edit.max_length = 32
	_build_palette_buttons()
	_apply_preview()
	btn_found.pressed.connect(_on_found_pressed)


func _build_palette_buttons() -> void:
	for child in palette_box.get_children():
		child.queue_free()
	var colors := {
		"blue": Color(0.25, 0.45, 0.85),
		"red": Color(0.8, 0.25, 0.22),
		"black": Color(0.2, 0.2, 0.22),
		"yellow": Color(0.9, 0.75, 0.2),
		"purple": Color(0.55, 0.3, 0.75),
	}
	for p in PALETTES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 36)
		btn.text = " "
		btn.modulate = colors.get(p, Color.WHITE)
		btn.tooltip_text = tr("guild_creation.palette.%s" % p)
		btn.pressed.connect(_select_palette.bind(p))
		palette_box.add_child(btn)


func _select_palette(p: String) -> void:
	_palette = p
	_apply_preview()


func _apply_preview() -> void:
	palette_name.text = tr("guild_creation.palette.%s" % _palette)
	var barracks_path := "res://assets/tiny_swords/buildings/%s/Barracks.png" % _palette
	if ResourceLoader.exists(barracks_path):
		preview_barracks.texture = load(barracks_path) as Texture2D
	# Guildmaster art is fixed; palette only recolors the hall.
	preview_unit.texture = _guildmaster_preview_texture()


func _guildmaster_preview_texture() -> Texture2D:
	if not ResourceLoader.exists(GM_FRAMES):
		return null
	var frames := load(GM_FRAMES) as SpriteFrames
	if frames == null:
		return null
	for anim in [&"idle_se", &"idle", &"run"]:
		if frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
			return frames.get_frame_texture(anim, 0)
	return null


func _on_found_pressed() -> void:
	var gname := name_edit.text.strip_edges()
	if gname.length() < 3 or gname.length() > 32:
		error_label.text = tr("guild_creation.error_name")
		return
	error_label.text = ""
	if _confirm == null:
		_confirm = ConfirmationDialog.new()
		_confirm.theme = theme
		add_child(_confirm)
		_confirm.confirmed.connect(_do_found)
	_confirm.title = tr("guild_creation.title")
	_confirm.dialog_text = tr("guild_creation.confirm") % gname
	_confirm.ok_button_text = tr("guild_creation.found")
	_confirm.get_cancel_button().text = tr("menu.back")
	_confirm.popup_centered()
	CampaignState.set_pending_guild(gname, _palette)


func _do_found() -> void:
	CampaignState.found_guild()
	var slot := SaveLoad.first_writable_slot()
	SaveLoad.save_campaign(slot)
	await SceneTransition.change_scene(HUB_SCENE)
