extends Node
## Persistent scene transitions (survives change_scene).

var _layer: CanvasLayer
var _rect: ColorRect


func _ensure() -> void:
	if _layer != null and is_instance_valid(_layer):
		return
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.name = "SceneTransitionLayer"
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_rect)
	get_tree().root.add_child(_layer)


func fade_out(duration := 0.4) -> void:
	_ensure()
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, duration)
	await tw.finished


func fade_in(duration := 0.35) -> void:
	_ensure()
	_rect.color.a = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 0.0, duration)
	await tw.finished


func change_scene(path: String, out_dur := 0.4, in_dur := 0.35) -> void:
	await fade_out(out_dur)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_in(in_dur)
