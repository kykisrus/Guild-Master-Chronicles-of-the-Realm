class_name GameMusicPlayer
extends AudioStreamPlayer

const TRACKS: Array[AudioStream] = [
	preload("res://assets/music/game/track_1.ogg"),
	preload("res://assets/music/game/track_2.ogg"),
	preload("res://assets/music/game/track_3.ogg"),
	preload("res://assets/music/game/track_4.ogg"),
	preload("res://assets/music/game/track_5.ogg"),
	preload("res://assets/music/game/track_6.ogg"),
	preload("res://assets/music/game/track_7.ogg"),
	preload("res://assets/music/game/track_8.ogg"),
	preload("res://assets/music/game/track_9.ogg"),
	preload("res://assets/music/game/track_10.ogg"),
	preload("res://assets/music/game/track_11.ogg"),
	preload("res://assets/music/game/track_12.ogg"),
]

var _queue: Array[AudioStream] = []
var _last_track: AudioStream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	finished.connect(_play_next)
	_refill_queue()
	call_deferred("_play_next")


func _refill_queue() -> void:
	_queue.assign(TRACKS)
	_queue.shuffle()
	if _last_track != null and _queue.size() > 1 and _queue.back() == _last_track:
		var swap_index := randi_range(0, _queue.size() - 2)
		var temp := _queue[swap_index]
		_queue[swap_index] = _queue.back()
		_queue[_queue.size() - 1] = temp


func _play_next() -> void:
	if _queue.is_empty():
		_refill_queue()
	_last_track = _queue.pop_back()
	stream = _last_track
	volume_db = -24.0
	play()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "volume_db", -11.0, 2.0)
