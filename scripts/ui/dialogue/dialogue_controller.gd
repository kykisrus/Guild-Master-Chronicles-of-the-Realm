extends CanvasLayer
## Reusable dialogue UI: speaker, text, choices, typewriter skip.

signal choice_selected(choice_id: String)
signal dialogue_finished

@onready var panel: PanelContainer = %Panel
@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var choices_box: VBoxContainer = %ChoicesBox
@onready var continue_hint: Label = %ContinueHint

var _full_text: String = ""
var _typing := false
var _type_tween: Tween
var _awaiting_continue := false


func _ready() -> void:
	visible = false
	var theme := TinyThemeFactory.build()
	panel.theme = theme
	# Theme must be on a Control ancestor so dynamic choice buttons inherit it.
	var root := get_node_or_null("Root") as Control
	if root != null:
		root.theme = theme
	continue_hint.text = tr("intro.dialogue_continue")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if _typing:
			_reveal_all()
			get_viewport().set_input_as_handled()
		elif _awaiting_continue and choices_box.get_child_count() == 0:
			_awaiting_continue = false
			dialogue_finished.emit()
			get_viewport().set_input_as_handled()


func show_line(speaker: String, text: String, typewriter := true) -> void:
	visible = true
	speaker_label.text = speaker
	_clear_choices()
	_full_text = text
	continue_hint.visible = true
	if typewriter:
		_start_typewriter(text)
		_awaiting_continue = true
	else:
		body_label.text = text
		_typing = false
		_awaiting_continue = true


func show_choices(choices: Array) -> void:
	## choices: Array of { "id": String, "text": String, "seen": bool }
	visible = true
	_clear_choices()
	continue_hint.visible = false
	_awaiting_continue = false
	_typing = false
	for c in choices:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var btn := Button.new()
		var label := str(c.get("text", ""))
		var seen := bool(c.get("seen", false))
		# Avoid Unicode checkmarks — Pix Cyrillic has no U+2713 (shows as "2713" tofu).
		if seen:
			btn.modulate = Color(0.72, 0.78, 0.72, 1.0)
			btn.disabled = false
		btn.text = label
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cid := str(c.get("id", ""))
		btn.pressed.connect(func() -> void: choice_selected.emit(cid))
		choices_box.add_child(btn)


func hide_dialogue() -> void:
	visible = false
	_clear_choices()
	_typing = false
	_awaiting_continue = false


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
