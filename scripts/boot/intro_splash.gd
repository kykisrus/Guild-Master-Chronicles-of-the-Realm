extends Control

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"

const LOGOS: Array[String] = [
	"res://assets/logos/godot_logo.png",
	"res://assets/company/logo_ams.png",
	"res://assets/company/logo_game.png",
]

const CAPTION_KEYS: Array[String] = [
	"splash.godot",
	"splash.ams",
	"splash.game",
]

@onready var logo: TextureRect = %Logo
@onready var caption: Label = %Caption
@onready var skip_hint: Label = %SkipHint

var _finished: bool = false


func _ready() -> void:
	theme = TinyThemeFactory.build()
	skip_hint.text = tr("menu.skip_splash")
	MusicController.play_intro(true)
	_play_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		_finish()


func _play_sequence() -> void:
	for i in LOGOS.size():
		if _finished:
			return
		var tex: Texture2D = load(LOGOS[i]) as Texture2D
		logo.texture = tex
		caption.text = tr(CAPTION_KEYS[i])
		logo.modulate.a = 0.0
		caption.modulate.a = 0.0
		var fade_in := create_tween().set_parallel()
		fade_in.tween_property(logo, "modulate:a", 1.0, 1.5)
		fade_in.tween_property(caption, "modulate:a", 1.0, 1.5)
		await fade_in.finished
		await get_tree().create_timer(4.0).timeout
		if _finished:
			return
		var fade_out := create_tween().set_parallel()
		fade_out.tween_property(logo, "modulate:a", 0.0, 1.5)
		fade_out.tween_property(caption, "modulate:a", 0.0, 1.5)
		await fade_out.finished
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	get_tree().change_scene_to_file(MENU_SCENE)
