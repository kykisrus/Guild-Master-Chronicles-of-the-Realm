extends Control

const LOGOS: Array[Texture2D] = [
	preload("res://icon.svg"),
	preload("res://assets/company/logo_ams.png"),
	preload("res://assets/company/logo_game.png"),
]

@onready var logo: TextureRect = %Logo
@onready var caption: Label = %Caption

var _finished: bool = false


func _ready() -> void:
	MusicController.play_intro(true)
	_play_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		_finish()


func _play_sequence() -> void:
	var captions := ["POWERED BY GODOT ENGINE", "A GAME BY AMS", "CHRONICLES BEGIN"]
	for i in LOGOS.size():
		if _finished:
			return
		logo.texture = LOGOS[i]
		caption.text = captions[i]
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
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
