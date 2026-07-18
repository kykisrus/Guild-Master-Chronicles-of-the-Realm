extends CanvasLayer
## Dialogue UI: baked Tiny Swords panel + UI avatars (not world sprites).

signal choice_selected(choice_id: String)
signal dialogue_finished

@onready var panel: PanelContainer = %Panel
@onready var portrait: TextureRect = %Portrait
@onready var portrait_frame: PanelContainer = %PortraitFrame
@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var continue_hint: Label = %ContinueHint

var _typing := false
var _type_tween: Tween
var _awaiting_continue := false
var _portrait_by_speaker: Dictionary = {}


func _ready() -> void:
	visible = false
	var root := get_node_or_null("Root") as Control
	if root != null:
		root.theme = TinySwordsThemeFactory.build()
	panel.add_theme_stylebox_override("panel", TinySwordsUi.style_from_sheet(TinySwordsUi.PAPER_SPECIAL, 14))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.08, 0.07, 0.06, 0.95)
	frame.border_color = Color(0.85, 0.72, 0.32, 1.0)
	frame.set_border_width_all(2)
	frame.set_content_margin_all(6)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_gui_input)
	continue_hint.text = tr("intro.dialogue_continue")
	_portrait_by_speaker = {
		"Проныра": TinySwordsUi.AVATAR_THIEF,
		"Гильдмастер": TinySwordsUi.AVATAR_GM,
	}


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		_handle_advance()
		get_viewport().set_input_as_handled()


func _on_panel_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_advance()
			panel.accept_event()


func _handle_advance() -> void:
	if _typing:
		_reveal_all()
	elif _awaiting_continue and choices_box.get_child_count() == 0:
		_awaiting_continue = false
		dialogue_finished.emit()


func show_line(speaker: String, text: String, typewriter := true) -> void:
	visible = true
	speaker_label.text = speaker
	_apply_portrait(speaker)
	_clear_choices()
	continue_hint.visible = true
	if typewriter:
		_start_typewriter(text)
		_awaiting_continue = true
	else:
		body_label.text = text
		body_label.visible_characters = -1
		_typing = false
		_awaiting_continue = true


func show_choices(choices: Array) -> void:
	visible = true
	_clear_choices()
	continue_hint.visible = false
	_awaiting_continue = false
	_typing = false
	for c in choices:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var btn := Button.new()
		var seen := bool(c.get("seen", false))
		btn.text = str(c.get("text", ""))
		if seen:
			btn.modulate = Color(0.78, 0.82, 0.75, 1.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cid := str(c.get("id", ""))
		btn.pressed.connect(func() -> void: choice_selected.emit(cid))
		choices_box.add_child(btn)


func hide_dialogue() -> void:
	visible = false
	_clear_choices()
	_typing = false
	_awaiting_continue = false


func _apply_portrait(speaker: String) -> void:
	var path := str(_portrait_by_speaker.get(speaker, TinySwordsUi.AVATAR_THIEF))
	var tex := TinySwordsUi.load_avatar(path)
	if tex != null:
		portrait.texture = tex
		portrait.visible = true
		portrait_frame.visible = true
	else:
		portrait_frame.visible = false


func _start_typewriter(text: String) -> void:
	_typing = true
	body_label.visible_characters = 0
	body_label.text = text
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	var chars := text.length()
	_type_tween = create_tween()
	_type_tween.tween_property(body_label, "visible_characters", chars, maxf(chars * 0.02, 0.2))
	_type_tween.finished.connect(func() -> void: _typing = false)


func _reveal_all() -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	body_label.visible_characters = -1
	_typing = false


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()
