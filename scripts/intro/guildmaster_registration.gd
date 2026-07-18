extends Control
## Guildmaster registration form.

const NEXT_SCENE := "res://scenes/intro/guild_creation.tscn"

const ORIGINS := [
	"gm_registration.origin.city",
	"gm_registration.origin.military",
	"gm_registration.origin.trade",
	"gm_registration.origin.rural",
	"gm_registration.origin.noble",
	"gm_registration.origin.wanderer",
]

@onready var title: Label = %Title
@onready var first_edit: LineEdit = %FirstName
@onready var last_edit: LineEdit = %LastName
@onready var age_spin: SpinBox = %Age
@onready var origin_opt: OptionButton = %Origin
@onready var error_label: Label = %ErrorLabel
@onready var btn_confirm: Button = %BtnConfirm
@onready var lbl_first: Label = %LblFirst
@onready var lbl_last: Label = %LblLast
@onready var lbl_age: Label = %LblAge
@onready var lbl_origin: Label = %LblOrigin


func _ready() -> void:
	theme = TinyThemeFactory.build()
	title.text = tr("gm_registration.title")
	lbl_first.text = tr("gm_registration.first_name")
	lbl_last.text = tr("gm_registration.last_name")
	lbl_age.text = tr("gm_registration.age")
	lbl_origin.text = tr("gm_registration.origin")
	btn_confirm.text = tr("menu.confirm")
	error_label.text = ""
	first_edit.max_length = 24
	last_edit.max_length = 24
	age_spin.min_value = 18
	age_spin.max_value = 80
	age_spin.value = 30
	origin_opt.clear()
	for key in ORIGINS:
		origin_opt.add_item(tr(key))
	origin_opt.select(0)
	btn_confirm.pressed.connect(_on_confirm)


func _on_confirm() -> void:
	var first := first_edit.text.strip_edges()
	var last := last_edit.text.strip_edges()
	var age := int(age_spin.value)
	if first.is_empty() or last.is_empty():
		error_label.text = tr("gm_registration.error_required")
		return
	if first.length() > 24 or last.length() > 24:
		error_label.text = tr("gm_registration.error_length")
		return
	if age < 18 or age > 80:
		error_label.text = tr("gm_registration.error_age")
		return
	if origin_opt.selected < 0:
		error_label.text = tr("gm_registration.error_origin")
		return
	var origin_key: String = ORIGINS[origin_opt.selected]
	CampaignState.set_pending_guildmaster({
		"first_name": first,
		"last_name": last,
		"age": age,
		"origin": tr(origin_key),
		"origin_key": origin_key,
		"gender": "male",
	})
	await SceneTransition.change_scene(NEXT_SCENE)
