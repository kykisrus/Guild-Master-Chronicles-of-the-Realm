extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CONFIRM_SCENE := "res://scenes/menu/confirmation_dialog.tscn"
const HUB_SCENE := "res://scenes/guild_hub/guild_hub.tscn"

@onready var slots_box: VBoxContainer = %SlotsBox
@onready var btn_back: Button = %BtnBack
@onready var title: Label = %Title

var _confirm: ConfirmationDialog
var _info: AcceptDialog
var _pending_delete_slot: int = 0


func _ready() -> void:
	theme = TinyThemeFactory.build()
	MusicController.enter_menu_context()
	title.text = tr("menu.load")
	btn_back.text = tr("menu.back")
	btn_back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	_rebuild_slots()


func _rebuild_slots() -> void:
	for child in slots_box.get_children():
		child.queue_free()
	for slot in range(1, SaveLoad.SLOT_COUNT + 1):
		slots_box.add_child(_make_slot_row(slot))


func _make_slot_row(slot: int) -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	margin.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var title_l := Label.new()
	title_l.text = tr("save.slot") % slot
	title_l.add_theme_font_size_override("font_size", 18)
	info.add_child(title_l)

	var status := Label.new()
	status.text = tr(SaveLoad.slot_status_key(slot))
	status.add_theme_font_size_override("font_size", 14)
	info.add_child(status)

	var meta := SaveLoad.slot_metadata(slot)
	if not meta.is_empty():
		var gname := str(meta.get("guild_name", ""))
		if gname.is_empty() and typeof(meta.get("guild", null)) == TYPE_DICTIONARY:
			gname = str(meta["guild"].get("name", ""))
		if not gname.is_empty():
			var g_l := Label.new()
			g_l.text = gname
			g_l.add_theme_font_size_override("font_size", 14)
			info.add_child(g_l)
		var saved_at := str(meta.get("saved_at", ""))
		if not saved_at.is_empty():
			var date_l := Label.new()
			date_l.text = tr("save.saved_at") % saved_at
			date_l.add_theme_font_size_override("font_size", 12)
			info.add_child(date_l)
		var ver: Variant = meta.get("save_version", null)
		var ver_l := Label.new()
		ver_l.text = tr("save.version") % (str(ver) if ver != null else "—")
		ver_l.add_theme_font_size_override("font_size", 12)
		info.add_child(ver_l)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	h.add_child(actions)

	var st: SaveLoad.SlotStatus = SaveLoad.get_slot_status(slot)
	match st:
		SaveLoad.SlotStatus.AVAILABLE:
			var load_btn := Button.new()
			load_btn.text = tr("menu.load")
			load_btn.pressed.connect(_on_load_pressed.bind(slot))
			actions.add_child(load_btn)
			var del_btn := Button.new()
			del_btn.text = tr("menu.delete")
			del_btn.pressed.connect(_on_delete_pressed.bind(slot))
			actions.add_child(del_btn)
		SaveLoad.SlotStatus.INCOMPATIBLE, SaveLoad.SlotStatus.CORRUPTED:
			var del_btn2 := Button.new()
			del_btn2.text = tr("menu.delete")
			del_btn2.pressed.connect(_on_delete_pressed.bind(slot))
			actions.add_child(del_btn2)
		_:
			var none := Label.new()
			none.text = tr("save.no_actions")
			none.add_theme_font_size_override("font_size", 12)
			actions.add_child(none)

	return panel


func _on_load_pressed(slot: int) -> void:
	var err := SaveLoad.load_campaign(slot)
	if err != "":
		_show_info(tr("menu.load"), err)
		return
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_delete_pressed(slot: int) -> void:
	_pending_delete_slot = slot
	if _confirm == null:
		_confirm = (load(CONFIRM_SCENE) as PackedScene).instantiate() as ConfirmationDialog
		add_child(_confirm)
		_confirm.confirmed.connect(_on_delete_confirmed)
	_confirm.setup_confirm_delete(slot)
	_confirm.popup_centered()


func _on_delete_confirmed() -> void:
	var err := SaveLoad.delete_save(_pending_delete_slot)
	if err != "":
		_show_info(tr("menu.delete"), err)
	_rebuild_slots()


func _show_info(title_text: String, body: String) -> void:
	if _info == null:
		_info = AcceptDialog.new()
		add_child(_info)
	_info.title = title_text
	_info.dialog_text = body
	_info.ok_button_text = tr("menu.ok")
	_info.popup_centered()
