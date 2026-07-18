extends Control
## Guildmaster registration: name + class only.

const NEXT_SCENE := "res://scenes/intro/guild_creation.tscn"

## Tiny Swords unit ids used as visual class.
const CLASSES := [
	{"id": "warrior", "key": "gm_registration.class.warrior"},
	{"id": "archer", "key": "gm_registration.class.archer"},
	{"id": "lancer", "key": "gm_registration.class.lancer"},
	{"id": "monk", "key": "gm_registration.class.monk"},
]

@onready var title: Label = %Title
@onready var name_edit: LineEdit = %HeroName
@onready var class_opt: OptionButton = %HeroClass
@onready var error_label: Label = %ErrorLabel
@onready var btn_confirm: Button = %BtnConfirm
@onready var lbl_name: Label = %LblName
@onready var lbl_class: Label = %LblClass


func _ready() -> void:
	theme = TinyThemeFactory.build()
	title.text = tr("gm_registration.title")
	lbl_name.text = tr("gm_registration.name")
	lbl_class.text = tr("gm_registration.class")
	btn_confirm.text = tr("menu.confirm")
	error_label.text = ""
	name_edit.max_length = 24
	class_opt.clear()
	for c in CLASSES:
		class_opt.add_item(tr(str(c["key"])))
	class_opt.select(0)
	btn_confirm.pressed.connect(_on_confirm)


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
