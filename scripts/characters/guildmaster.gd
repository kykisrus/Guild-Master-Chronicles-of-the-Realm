extends Node2D
## Autonomous Guildmaster — custom character art; no direct player movement.

signal arrived
signal interaction_finished

const CUSTOM_FRAMES := "res://resources/sprite_frames/characters/guildmaster.tres"
const FALLBACK_FRAMES := "res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres"

enum State { IDLE, WALKING, INTERACTING, ENTERING, TALKING }

@export var move_speed: float = 110.0
@export var sprite_frames_path: String = CUSTOM_FRAMES

var sprite: AnimatedSprite2D

var _state: State = State.IDLE
var _tween: Tween
var _facing: String = "se"


func _ready() -> void:
	sprite = %Sprite as AnimatedSprite2D
	if not ResourceLoader.exists(sprite_frames_path):
		sprite_frames_path = FALLBACK_FRAMES
	_apply_frames(sprite_frames_path)
	set_state(State.IDLE)


func set_palette_frames(_palette: String) -> void:
	# Custom guildmaster art is fixed; guild palette is data-only for now.
	pass


func set_unit_frames(_class_id: String, _palette: String) -> void:
	# Class choice does not swap the guildmaster sprite (preview uses Tiny Swords).
	pass


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
			_play_idle(spr)
		State.WALKING:
			_play_walk(spr)
		State.ENTERING:
			if spr.sprite_frames.has_animation(&"enter"):
				spr.play(&"enter")
			else:
				_play_walk(spr)


func _play_idle(spr: AnimatedSprite2D) -> void:
	spr.flip_h = _facing in ["w", "sw", "nw"]
	var anim := _idle_anim_for_facing()
	if spr.sprite_frames.has_animation(anim):
		spr.play(anim)
	elif spr.sprite_frames.has_animation(&"idle_se"):
		spr.play(&"idle_se")
	elif spr.sprite_frames.has_animation(&"idle"):
		spr.play(&"idle")


func _play_walk(spr: AnimatedSprite2D) -> void:
	# Generated 8-dir walk columns are unreliable; prefer authored SE cycle + flip.
	spr.flip_h = _facing in ["w", "sw", "nw"]
	if _facing in ["n", "ne", "nw"]:
		if spr.sprite_frames.has_animation(&"walk_n"):
			spr.play(&"walk_n")
			return
		if spr.sprite_frames.has_animation(&"idle_n"):
			spr.play(&"idle_n")
			return
	if spr.sprite_frames.has_animation(&"run"):
		spr.play(&"run")
	elif spr.sprite_frames.has_animation(&"walk_se"):
		spr.play(&"walk_se")
	elif spr.sprite_frames.has_animation(&"walk"):
		spr.play(&"walk")
	elif spr.sprite_frames.has_animation(&"idle"):
		spr.play(&"idle")


func _idle_anim_for_facing() -> StringName:
	match _facing:
		"n", "ne", "nw":
			return &"idle_n"
		"e", "se", "s":
			return &"idle_se"
		"w", "sw":
			return &"idle_se" # flipped in _play_idle via flip when walking; keep se for idle west
		_:
			return &"idle_se"


func _facing_from_delta(delta: Vector2) -> String:
	if delta.length_squared() < 0.01:
		return _facing
	var ang := atan2(delta.y, delta.x)
	var deg := rad_to_deg(ang)
	if deg < 0.0:
		deg += 360.0
	var idx := int(floor((deg + 22.5) / 45.0)) % 8
	var names := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	return names[idx]


func walk_to(global_target: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var delta := global_target - global_position
	_facing = _facing_from_delta(delta)
	var spr := _ensure_sprite()
	if spr != null:
		# Directional sheets include mirrored facings; avoid double-flip.
		spr.flip_h = false
	set_state(State.WALKING)
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
	var spr := _ensure_sprite()
	var wait := 0.45
	if spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation(&"enter"):
		var n := spr.sprite_frames.get_frame_count(&"enter")
		var spd := spr.sprite_frames.get_animation_speed(&"enter")
		wait = maxf(float(n) / maxf(spd, 1.0), 0.35)
	await get_tree().create_timer(wait).timeout
	set_state(State.IDLE)
	interaction_finished.emit()
