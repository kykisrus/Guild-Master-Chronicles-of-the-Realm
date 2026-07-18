class_name ClickableTarget
extends Area2D
## Clickable world object: hover + clicked signal for building/door navigation.

signal clicked

@export var hover_modulate: Color = Color(1.15, 1.15, 1.05, 1.0)

var _base_modulate: Color = Color.WHITE
var _visual: CanvasItem
var _enabled := true


func setup(visual: CanvasItem, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	_visual = visual
	if visual != null:
		_base_modulate = visual.modulate
	monitoring = true
	monitorable = false
	input_pickable = true
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	add_child(cs)
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	input_event.connect(_on_input_event)


func set_click_enabled(v: bool) -> void:
	_enabled = v
	input_pickable = v
	if not v and _visual != null:
		_visual.modulate = _base_modulate


func _on_enter() -> void:
	if _enabled and _visual != null:
		_visual.modulate = hover_modulate


func _on_exit() -> void:
	if _visual != null:
		_visual.modulate = _base_modulate


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			get_viewport().set_input_as_handled()
