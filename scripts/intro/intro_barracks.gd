extends Node2D
## Kings and Pigs interior + thief dialogue; door click returns to field.

const FIELD_SCENE := "res://scenes/intro/intro_field.tscn"
const REG_SCENE := "res://scenes/intro/guildmaster_registration.tscn"
const GM_SCENE := "res://scenes/characters/guildmaster.tscn"
const DOOR_SCENE := "res://scenes/assets/kings_and_pigs/basic_door.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue/dialogue_box.tscn"
const DIALOGUE_DATA := "res://data/intro/thief_dialogue.json"
## Tiny Swords black Pawn — temporary stand-in until custom Проныра art (see character design doc).
const THIEF_FRAMES := "res://resources/sprite_frames/characters/pronyra.tres"
const ROOM_W := 960.0
const ROOM_H := 540.0

@onready var world: Node2D = %World
@onready var camera: Camera2D = %Camera2D
@onready var skip_btn: Button = %BtnSkip

var _gm: Node2D
var _thief: AnimatedSprite2D
var _door: Node2D
var _door_click: ClickableTarget
var _dialogue: CanvasLayer
var _data: Dictionary = {}
var _seen: Dictionary = {}
var _phase: String = "opening"
var _line_i := 0
var _skip_confirm: ConfirmationDialog
var _waiting_line := false
var _busy := false


func _ready() -> void:
	_build_room()
	_load_dialogue_data()
	_dialogue = (load(DIALOGUE_SCENE) as PackedScene).instantiate()
	add_child(_dialogue)
	_dialogue.choice_selected.connect(_on_choice)
	_dialogue.dialogue_finished.connect(_on_line_finished)
	skip_btn.theme = TinySwordsThemeFactory.build()
	skip_btn.text = tr("intro.skip")
	skip_btn.pressed.connect(_on_skip_pressed)
	camera.position = Vector2(ROOM_W * 0.5, ROOM_H * 0.5)
	camera.make_current()
	await get_tree().process_frame
	_refresh_door_click()
	_start_opening()


func _build_room() -> void:
	var floor := ColorRect.new()
	floor.color = Color(0.22, 0.18, 0.16)
	floor.size = Vector2(ROOM_W, ROOM_H)
	world.add_child(floor)
	var wall := ColorRect.new()
	wall.color = Color(0.32, 0.26, 0.22)
	wall.size = Vector2(ROOM_W, 120)
	world.add_child(wall)

	_door = (load(DOOR_SCENE) as PackedScene).instantiate()
	_door.position = Vector2(120, 280)
	world.add_child(_door)

	_door_click = ClickableTarget.new()
	_door_click.name = "DoorClick"
	_door.add_child(_door_click)
	_door_click.setup(_door, Vector2(80, 120), Vector2(0, -20))
	_door_click.clicked.connect(_on_door_clicked)

	_gm = (load(GM_SCENE) as PackedScene).instantiate()
	_gm.position = Vector2(220, 360)
	world.add_child(_gm)

	_thief = AnimatedSprite2D.new()
	_thief.name = "ThiefPronyra"
	if ResourceLoader.exists(THIEF_FRAMES):
		_thief.sprite_frames = load(THIEF_FRAMES) as SpriteFrames
		if _thief.sprite_frames.has_animation(&"idle"):
			_thief.play(&"idle")
		elif _thief.sprite_frames.has_animation(&"run"):
			_thief.play(&"run")
	_thief.position = Vector2(620, 360)
	_thief.flip_h = true
	_thief.offset = Vector2(0, -96)
	_thief.scale = Vector2(1.0, 1.0)
	world.add_child(_thief)


func _load_dialogue_data() -> void:
	var f := FileAccess.open(DIALOGUE_DATA, FileAccess.READ)
	if f == null:
		push_error("Missing thief dialogue data")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed


func _speaker_name(key: String) -> String:
	var speakers: Dictionary = _data.get("speakers", {})
	return str(speakers.get(key, key))


func _start_opening() -> void:
	_phase = "opening"
	_line_i = 0
	_show_next_opening()


func _show_next_opening() -> void:
	var lines: Array = _data.get("opening", [])
	if _line_i >= lines.size():
		_show_question_menu()
		return
	var line: Dictionary = lines[_line_i]
	_line_i += 1
	_waiting_line = true
	_dialogue.show_line(_speaker_name(str(line.get("speaker", ""))), tr(str(line.get("text_key", ""))))
	_refresh_door_click()


func _show_question_menu() -> void:
	_phase = "questions"
	var choices: Array = []
	for q in _data.get("questions", []):
		if typeof(q) != TYPE_DICTIONARY:
			continue
		var qid := str(q.get("id", ""))
		choices.append({
			"id": qid,
			"text": tr(str(q.get("text_key", ""))),
			"seen": bool(_seen.get(qid, false)),
		})
	_dialogue.speaker_label.text = _speaker_name("thief")
	_dialogue.body_label.text = tr("intro.ask_me")
	_dialogue.show_choices(choices)
	_refresh_door_click()


func _on_line_finished() -> void:
	if not _waiting_line:
		return
	_waiting_line = false
	match _phase:
		"opening":
			_show_next_opening()
		"answer":
			_show_question_menu()
		"ready_prompt_wait":
			_show_ready_choices()
		"farewell":
			_after_farewell()
		_:
			pass
	_refresh_door_click()


func _on_choice(choice_id: String) -> void:
	if _phase == "ready_choices":
		if choice_id == "more":
			_show_question_menu()
		elif choice_id == "ready":
			_begin_farewell()
		return

	if choice_id == "ready":
		_show_ready_prompt()
		return

	for q in _data.get("questions", []):
		if typeof(q) != TYPE_DICTIONARY:
			continue
		if str(q.get("id", "")) != choice_id:
			continue
		_seen[choice_id] = true
		_phase = "answer"
		_waiting_line = true
		_dialogue.show_line(_speaker_name("thief"), tr(str(q.get("answer_key", ""))))
		_refresh_door_click()
		return


func _show_ready_prompt() -> void:
	_phase = "ready_prompt_wait"
	var prompt: Dictionary = _data.get("ready_prompt", {})
	_waiting_line = true
	_dialogue.show_line(_speaker_name(str(prompt.get("speaker", "thief"))), tr(str(prompt.get("text_key", "intro.ready_prompt"))))
	_refresh_door_click()


func _show_ready_choices() -> void:
	_phase = "ready_choices"
	var prompt: Dictionary = _data.get("ready_prompt", {})
	var choices: Array = []
	for c in prompt.get("choices", []):
		if typeof(c) != TYPE_DICTIONARY:
			continue
		choices.append({
			"id": str(c.get("id", "")),
			"text": tr(str(c.get("text_key", ""))),
			"seen": false,
		})
	_dialogue.show_choices(choices)
	_refresh_door_click()


func _begin_farewell() -> void:
	_phase = "farewell"
	_line_i = 0
	_show_farewell_line()


func _show_farewell_line() -> void:
	var lines: Array = _data.get("farewell", [])
	if _line_i >= lines.size():
		_after_farewell()
		return
	var line: Dictionary = lines[_line_i]
	_line_i += 1
	_waiting_line = true
	_dialogue.show_line(_speaker_name(str(line.get("speaker", "thief"))), tr(str(line.get("text_key", ""))))
	_refresh_door_click()


func _after_farewell() -> void:
	_busy = true
	_refresh_door_click()
	_dialogue.hide_dialogue()
	if _thief != null:
		var tw := create_tween()
		tw.tween_property(_thief, "position", Vector2(140, 300), 1.2)
		await tw.finished
		if _door != null and _door.has_method("open_door"):
			_door.open_door()
			await get_tree().create_timer(0.5).timeout
		_thief.visible = false
	await SceneTransition.change_scene(REG_SCENE)


func _door_nav_allowed() -> bool:
	if _busy or _waiting_line:
		return false
	# Allow leaving to field during choice menus (before «Я готов»).
	return _phase == "questions" or _phase == "ready_choices"


func _refresh_door_click() -> void:
	if _door_click != null:
		_door_click.set_click_enabled(_door_nav_allowed())


func _on_door_clicked() -> void:
	if not _door_nav_allowed() or _gm == null:
		return
	_busy = true
	_refresh_door_click()
	if _dialogue != null:
		_dialogue.hide_dialogue()
	await _gm.walk_to(Vector2(140, 300))
	if _door != null and _door.has_method("open_door"):
		_door.open_door()
		await get_tree().create_timer(0.35).timeout
	await SceneTransition.change_scene(FIELD_SCENE)


func _on_skip_pressed() -> void:
	if _skip_confirm == null:
		_skip_confirm = ConfirmationDialog.new()
		_skip_confirm.theme = TinySwordsThemeFactory.build()
		add_child(_skip_confirm)
		_skip_confirm.confirmed.connect(_do_skip)
	_skip_confirm.title = tr("intro.skip")
	_skip_confirm.dialog_text = tr("intro.skip_confirm")
	_skip_confirm.ok_button_text = tr("intro.skip")
	_skip_confirm.get_cancel_button().text = tr("menu.cancel")
	_skip_confirm.popup_centered()


func _do_skip() -> void:
	_busy = true
	await SceneTransition.change_scene(REG_SCENE)
