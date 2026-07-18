extends Camera2D
## Hub camera: WASD, edge scroll, MMB drag, wheel zoom. Not character-bound.

@export var move_speed: float = 420.0
@export var edge_margin: float = 24.0
@export var edge_speed: float = 380.0
@export var zoom_min: float = 0.55
@export var zoom_max: float = 1.6
@export var map_size: Vector2 = Vector2(2048, 1536)

var _dragging := false
var _drag_last := Vector2.ZERO


func _ready() -> void:
	make_current()
	_clamp_position()


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * move_speed * delta / zoom.x

	var vp := get_viewport().get_visible_rect().size
	var mouse := get_viewport().get_mouse_position()
	var edge := Vector2.ZERO
	if mouse.x <= edge_margin:
		edge.x -= 1.0
	elif mouse.x >= vp.x - edge_margin:
		edge.x += 1.0
	if mouse.y <= edge_margin:
		edge.y -= 1.0
	elif mouse.y >= vp.y - edge_margin:
		edge.y += 1.0
	if edge != Vector2.ZERO and not _dragging:
		position += edge.normalized() * edge_speed * delta / zoom.x

	_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_drag_last = mb.position
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * 1.1).clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / 1.1).clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		position -= mm.relative / zoom.x
		_clamp_position()


func _clamp_position() -> void:
	var half := get_viewport_rect().size * 0.5 / zoom.x
	position.x = clampf(position.x, half.x, map_size.x - half.x)
	position.y = clampf(position.y, half.y, map_size.y - half.y)
