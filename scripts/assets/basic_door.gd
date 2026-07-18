extends Node2D
## Kings and Pigs door with closed / opening / open / closing states.

signal state_changed(state: StringName)

const FRAMES_PATH := "res://resources/sprite_frames/kings_and_pigs/door.tres"

@onready var sprite: AnimatedSprite2D = %DoorSprite

var _state: StringName = &"closed"


func _ready() -> void:
	if ResourceLoader.exists(FRAMES_PATH):
		sprite.sprite_frames = load(FRAMES_PATH) as SpriteFrames
	_play_state(&"closed")
	sprite.animation_finished.connect(_on_anim_finished)


func get_state() -> StringName:
	return _state


func open_door() -> void:
	if _state == &"open" or _state == &"opening":
		return
	_play_state(&"opening")


func close_door() -> void:
	if _state == &"closed" or _state == &"closing":
		return
	_play_state(&"closing")


func _play_state(state: StringName) -> void:
	_state = state
	state_changed.emit(_state)
	if sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(state):
		sprite.play(state)
	elif state == &"open" and sprite.sprite_frames.has_animation(&"opening"):
		# Hold last opening frame
		sprite.play(&"opening")
		sprite.frame = maxi(sprite.sprite_frames.get_frame_count(&"opening") - 1, 0)
		sprite.pause()


func _on_anim_finished() -> void:
	if _state == &"opening":
		_state = &"open"
		state_changed.emit(_state)
		if sprite.sprite_frames.has_animation(&"opening"):
			sprite.frame = maxi(sprite.sprite_frames.get_frame_count(&"opening") - 1, 0)
			sprite.pause()
	elif _state == &"closing":
		_play_state(&"closed")
