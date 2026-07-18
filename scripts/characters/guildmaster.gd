extends Node2D
## Autonomous Guildmaster — no direct player movement control.

signal arrived
signal interaction_finished

const DEFAULT_FRAMES := "res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres"

enum State { IDLE, WALKING, INTERACTING, ENTERING, TALKING }

@export var move_speed: float = 110.0
@export var sprite_frames_path: String = DEFAULT_FRAMES

var sprite: AnimatedSprite2D

var _state: State = State.IDLE
var _tween: Tween


func _ready() -> void:
	sprite = %Sprite as AnimatedSprite2D
	_apply_frames(sprite_frames_path)
	set_state(State.IDLE)


func set_palette_frames(palette: String) -> void:
	var p := palette.to_lower()
	var path := "res://resources/sprite_frames/tiny_swords/unit_warrior_%s.tres" % p
	if ResourceLoader.exists(path):
		sprite_frames_path = path
		_apply_frames(path)


func _ensure_sprite() -> AnimatedSprite2D:
	if sprite == null:
		sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	return sprite


func _apply_frames(path: String) -> void:
	var spr := _ensure_sprite()
	if spr == null or not ResourceLoader.exists(path):
		return
	spr.sprite_frames = load(path) as SpriteFrames


func set_state(s: State) -> void:
	_state = s
	var spr := _ensure_sprite()
	if spr == null or spr.sprite_frames == null:
		return
	match s:
		State.IDLE, State.TALKING, State.INTERACTING:
			if spr.sprite_frames.has_animation(&"idle"):
				spr.play(&"idle")
		State.WALKING, State.ENTERING:
			if spr.sprite_frames.has_animation(&"run"):
				spr.play(&"run")
			elif spr.sprite_frames.has_animation(&"idle"):
				spr.play(&"idle")


func walk_to(global_target: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	set_state(State.WALKING)
	var delta := global_target - global_position
	var spr := _ensure_sprite()
	if spr != null:
		spr.flip_h = delta.x < 0.0
	var dist := delta.length()
	var dur := maxf(dist / move_speed, 0.05)
	_tween = create_tween()
	_tween.tween_property(self, "global_position", global_target, dur)
	await _tween.finished
	set_state(State.IDLE)
	arrived.emit()


func walk_path(points: Array[Vector2]) -> void:
	for p in points:
		await walk_to(p)


func play_enter_building() -> void:
	set_state(State.ENTERING)
	await get_tree().create_timer(0.35).timeout
	set_state(State.IDLE)
	interaction_finished.emit()
