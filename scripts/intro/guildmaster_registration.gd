extends Control
## Guildmaster registration: name only; preview is always the guildmaster.

const NEXT_SCENE := "res://scenes/intro/guild_creation.tscn"
const GM_FRAMES := "res://resources/sprite_frames/characters/guildmaster.tres"
const GM_CLASS_ID := "guildmaster"
const GM_CLASS_KEY := "gm_registration.role"

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var name_edit: LineEdit = %HeroName
@onready var class_opt: OptionButton = %HeroClass
@onready var error_label: Label = %ErrorLabel
@onready var btn_confirm: Button = %BtnConfirm
@onready var lbl_name: Label = %LblName
@onready var lbl_class: Label = %LblClass
@onready var preview: AnimatedSprite2D = %PreviewSprite
@onready var preview_label: Label = %PreviewLabel
@onready var preview_frame: PanelContainer = %PreviewFrame
@onready var preview_host: Control = %PreviewHost
@onready var card: NinePatchRect = %Card


func _ready() -> void:
	theme = TinySwordsThemeFactory.build()
	_apply_tiny_swords_card()
	_style_preview_frame()
	title.text = tr("gm_registration.title")
	subtitle.text = tr("gm_registration.subtitle")
	lbl_name.text = tr("gm_registration.name")
	lbl_class.visible = false
	class_opt.visible = false
	btn_confirm.text = tr("menu.confirm")
	error_label.text = ""
	name_edit.max_length = 24
	name_edit.placeholder_text = ""
	btn_confirm.pressed.connect(_on_confirm)
	_refresh_preview()
	preview_host.resized.connect(_center_preview)
	call_deferred("_center_preview")
	call_deferred("_focus_name")


func _apply_tiny_swords_card() -> void:
	TinySwordsUi.apply_nine_patch(card, TinySwordsUi.PAPER_SPECIAL, TinySwordsUi.PANEL_MAX_TEX_MARGIN)
	btn_confirm.add_theme_stylebox_override("normal", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	btn_confirm.add_theme_stylebox_override("hover", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	btn_confirm.add_theme_stylebox_override("pressed", TinySwordsUi.style_from_sheet(TinySwordsUi.BTN_BLUE_PRESSED, 10, TinySwordsUi.DEFAULT_MAX_TEX_MARGIN))
	btn_confirm.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92, 1.0))
	btn_confirm.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn_confirm.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.7, 1))


func _focus_name() -> void:
	if is_inside_tree() and name_edit != null:
		name_edit.grab_focus()


func _center_preview() -> void:
	if preview_host == null or preview == null:
		return
	preview.position = preview_host.size * 0.5 + Vector2(0, 36)


func _style_preview_frame() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	box.border_color = Color(0.55, 0.45, 0.28, 1.0)
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	preview_frame.add_theme_stylebox_override("panel", box)


func _refresh_preview() -> void:
	preview_label.text = tr(GM_CLASS_KEY)
	preview.scale = Vector2(1.0, 1.0)
	preview.offset = Vector2(0, -64)
	var path := GM_FRAMES
	if not ResourceLoader.exists(path):
		path = "res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres"
	var frames := load(path) as SpriteFrames
	if frames == null:
		return
	preview.sprite_frames = frames
	if frames.has_animation(&"idle_se"):
		preview.play(&"idle_se")
	elif frames.has_animation(&"idle"):
		preview.play(&"idle")
	elif frames.has_animation(&"run"):
		preview.play(&"run")


func _on_confirm() -> void:
	var hero_name := name_edit.text.strip_edges()
	if hero_name.is_empty():
		error_label.text = tr("gm_registration.error_required")
		return
	if hero_name.length() > 24:
		error_label.text = tr("gm_registration.error_length")
		return
	CampaignState.set_pending_guildmaster({
		"name": hero_name,
		"first_name": hero_name,
		"last_name": "",
		"class_id": GM_CLASS_ID,
		"class_name": tr(GM_CLASS_KEY),
		"gender": "male",
	})
	await SceneTransition.change_scene(NEXT_SCENE)
