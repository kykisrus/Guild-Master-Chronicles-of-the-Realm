extends Node

signal intro_finished
signal menu_theme_started

const INTRO_STREAM := preload("res://assets/company/intro.wav")
const MENU_STREAM := preload("res://assets/main_menu/main_menu_theme.ogg")

var _player: AudioStreamPlayer
var _menu_context: bool = false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "PersistentMusic"
	_player.volume_db = -8.0
	add_child(_player)
	_player.finished.connect(_on_track_finished)
	if Settings != null:
		set_music_volume(Settings.music_volume)


func set_music_volume(linear: float) -> void:
	if _player == null:
		return
	var v := clampf(linear, 0.0, 1.0)
	_player.volume_db = linear_to_db(v) if v > 0.001 else -80.0


func play_intro(restart: bool = false) -> void:
	_menu_context = true
	if _player.stream == INTRO_STREAM and _player.playing and not restart:
		return
	_player.stream = INTRO_STREAM
	_player.play()


func enter_menu_context() -> void:
	_menu_context = true
	if _player.playing:
		return
	_start_menu_theme()


func leave_menu_context() -> void:
	_menu_context = false
	_player.stop()


func is_intro_playing() -> bool:
	return _player.playing and _player.stream == INTRO_STREAM


func is_menu_theme_playing() -> bool:
	return _player.playing and _player.stream == MENU_STREAM


func current_position() -> float:
	return _player.get_playback_position() if _player.playing else 0.0


func _on_track_finished() -> void:
	if _player.stream == INTRO_STREAM:
		intro_finished.emit()
		if _menu_context:
			_start_menu_theme()
	elif _player.stream == MENU_STREAM and _menu_context:
		_start_menu_theme()


func _start_menu_theme() -> void:
	_player.stream = MENU_STREAM
	_player.play()
	menu_theme_started.emit()
