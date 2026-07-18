extends Control
## Guildmaster registration with live Tiny Swords class preview.

const NEXT_SCENE := "res://scenes/intro/guild_creation.tscn"

const CLASSES := [
	{"id": "warrior", "key": "gm_registration.class.warrior"},
	{"id": "archer", "key": "gm_registration.class.archer"},
	{"id": "lancer", "key": "gm_registration.class.lancer"},
	{"id": "monk", "key": "gm_registration.class.monk"},
]

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


func _ready() -> void:
	theme = TinyThemeFactory.build()
	_style_preview_frame()
	title.text = tr("gm_registration.title")
	subtitle.text = tr("gm_registration.subtitle")
	lbl_name.text = tr("gm_registration.name")
	lbl_class.text = tr("gm_registration.class")
	btn_confirm.text = tr("menu.confirm")
	error_label.text = ""
	name_edit.max_length = 24
	name_edit.placeholder_text = ""
	class_opt.clear()
	for c in CLASSES:
		class_opt.add_item(tr(str(c["key"])))
	class_opt.select(0)
	class_opt.item_selected.connect(_on_class_selected)
	btn_confirm.pressed.connect(_on_confirm)
	_refresh_preview(0)
	preview_host.resized.connect(_center_preview)
	call_deferred("_center_preview")
	call_deferred("_focus_name")


func _focus_name() -> void:
	if is_inside_tree() and name_edit != null:
		name_edit.grab_focus()


func _center_preview() -> void:
	if preview_host == null or preview == null:
		return
	preview.position = preview_host.size * 0.5 + Vector2(0, 24)


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


func _on_class_selected(index: int) -> void:
	_refresh_preview(index)


func _refresh_preview(index: int) -> void:
	if index < 0 or index >= CLASSES.size():
		return
	var class_id := str(CLASSES[index]["id"])
	preview_label.text = tr(str(CLASSES[index]["key"]))
	var path := "res://resources/sprite_frames/tiny_swords/unit_%s_blue.tres" % class_id
	if not ResourceLoader.exists(path):
		path = "res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres"
	var frames := load(path) as SpriteFrames
	if frames == null:
		return
	preview.sprite_frames = frames
	if frames.has_animation(&"idle"):
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
	if class_opt.selected < 0 or class_opt.selected >= CLASSES.size():
		error_label.text = tr("gm_registration.error_class")
		return
	var class_data: Dictionary = CLASSES[class_opt.selected]
	var class_id := str(class_data["id"])
	CampaignState.set_pending_guildmaster({
		"name": hero_name,
		"first_name": hero_name,
		"last_name": "",
		"class_id": class_id,
		"class_name": tr(str(class_data["key"])),
		"gender": "male",
	})
	await SceneTransition.change_scene(NEXT_SCENE)
