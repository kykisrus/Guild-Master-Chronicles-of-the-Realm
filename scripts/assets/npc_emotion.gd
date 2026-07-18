extends Node2D
## Floating emotion bubble for Tiny Neighbours NPCs.

const EMOTION_FRAMES := {
	&"angry": "res://resources/sprite_frames/tiny_neighbours/emotion_angry.tres",
	&"evil": "res://resources/sprite_frames/tiny_neighbours/emotion_evil.tres",
	&"exclamation": "res://resources/sprite_frames/tiny_neighbours/emotion_exclamation.tres",
	&"happy": "res://resources/sprite_frames/tiny_neighbours/emotion_happy.tres",
	&"broken_heart": "res://resources/sprite_frames/tiny_neighbours/emotion_broken_heart.tres",
	&"heart": "res://resources/sprite_frames/tiny_neighbours/emotion_heart.tres",
	&"question": "res://resources/sprite_frames/tiny_neighbours/emotion_question.tres",
	&"sad": "res://resources/sprite_frames/tiny_neighbours/emotion_sad.tres",
	&"star": "res://resources/sprite_frames/tiny_neighbours/emotion_star.tres",
	&"surprised": "res://resources/sprite_frames/tiny_neighbours/emotion_surprised.tres",
}

@onready var sprite: AnimatedSprite2D = %EmotionSprite

var _hide_timer: Timer


func _ready() -> void:
	sprite.visible = false
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(stop_emotion)
	add_child(_hide_timer)


func play_emotion(emotion_id: StringName) -> void:
	if not EMOTION_FRAMES.has(emotion_id):
		push_warning("Unknown emotion: %s" % emotion_id)
		return
	var path: String = EMOTION_FRAMES[emotion_id]
	if not ResourceLoader.exists(path):
		push_warning("Emotion frames missing: %s" % path)
		return
	sprite.sprite_frames = load(path) as SpriteFrames
	sprite.visible = true
	if sprite.sprite_frames.has_animation(emotion_id):
		sprite.play(emotion_id)
	else:
		var names := sprite.sprite_frames.get_animation_names()
		if names.size() > 0:
			sprite.play(names[0])
	_hide_timer.start(2.0)


func stop_emotion() -> void:
	sprite.stop()
	sprite.visible = false
