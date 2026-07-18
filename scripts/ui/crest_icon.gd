class_name CrestIcon
extends Control

## Многослойный герб, воспроизводимый по параметрам кампании.

var fill_color: Color = Color("8b2e2e")
var secondary_color: Color = Color("E8E0CA")
var charge_color: Color = Color("C59413")
var rim_color: Color = Color("D9AE55")
var emblem_id: String = "star"
var pattern_id: String = "solid"
var shield_id: String = "heater"
var border_id: String = "gold_simple"


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(64, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(p_color: Color, p_emblem_id: String, p_pattern_id: String = "solid") -> void:
	fill_color = p_color
	emblem_id = p_emblem_id
	pattern_id = p_pattern_id
	queue_redraw()


func setup_full(config: Dictionary) -> void:
	fill_color = config.get("primary", fill_color)
	secondary_color = config.get("secondary", secondary_color)
	charge_color = config.get("charge", charge_color)
	emblem_id = str(config.get("emblem", emblem_id))
	pattern_id = str(config.get("pattern", pattern_id))
	shield_id = str(config.get("shield", shield_id))
	border_id = str(config.get("border", border_id))
	match border_id:
		"silver_simple":
			rim_color = Color("AAB3BE")
		"iron_simple":
			rim_color = Color("566171")
		_:
			rim_color = Color("D9AE55")
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var pts := _shield_points(w, h)
	var deep := fill_color.darkened(0.32)
	draw_colored_polygon(pts, deep)
	var inner := _scaled_points(pts, Vector2(cx, h * 0.5), 0.86)
	draw_colored_polygon(inner, fill_color)
	_draw_pattern(inner, w, h, cx, secondary_color, deep)
	## верхний блик и нижняя тень придают щиту объём
	var inner_outline := inner.duplicate()
	inner_outline.append(inner[0])
	draw_polyline(inner_outline, Color(1, 1, 1, 0.18), 1.4, true)
	if border_id != "none":
		for i in pts.size():
			draw_line(pts[i], pts[(i + 1) % pts.size()], Color("10141B"), 5.0, true)
			draw_line(pts[i], pts[(i + 1) % pts.size()], rim_color, 3.0, true)
			draw_line(pts[i], pts[(i + 1) % pts.size()], rim_color.lightened(0.2), 1.0, true)

	var ink := charge_color
	var c := Vector2(cx, h * 0.48)
	if _draw_vector_charge(c, mini(w, h) * 0.52):
		return
	match emblem_id:
		"lion":
			_draw_lion(c, mini(w, h) * 0.24, ink)
		"wolf":
			_draw_wolf(c, mini(w, h) * 0.25, ink)
		"dragon":
			draw_polyline(PackedVector2Array([
				c + Vector2(-14, 8), c + Vector2(-4, -10), c + Vector2(6, 2), c + Vector2(14, -8)
			]), ink, 2.5, true)
		"eagle":
			draw_polyline(PackedVector2Array([
				c + Vector2(-16, 4), c, c + Vector2(16, 4), c + Vector2(0, -10), c + Vector2(-16, 4)
			]), ink, 2.0, true)
		"sword":
			draw_line(c + Vector2(0, -16), c + Vector2(0, 14), ink, 3.0, true)
			draw_line(c + Vector2(-10, -2), c + Vector2(10, -2), ink, 2.5, true)
		"cross":
			draw_line(c + Vector2(0, -14), c + Vector2(0, 14), ink, 3.0, true)
			draw_line(c + Vector2(-12, 0), c + Vector2(12, 0), ink, 3.0, true)
		"tower":
			draw_rect(Rect2(c.x - 8, c.y - 12, 16, 24), ink, false, 2.0)
			draw_line(c + Vector2(-8, -12), c + Vector2(-8, -18), ink, 2.0, true)
			draw_line(c + Vector2(0, -12), c + Vector2(0, -18), ink, 2.0, true)
			draw_line(c + Vector2(8, -12), c + Vector2(8, -18), ink, 2.0, true)
		"star":
			_draw_star(c, mini(w, h) * 0.16, ink)
		"tree":
			draw_line(c + Vector2(0, 12), c + Vector2(0, -4), ink, 3.0, true)
			draw_circle(c + Vector2(0, -8), 10, ink)
		"flame":
			draw_polyline(PackedVector2Array([
				c + Vector2(-8, 10), c + Vector2(-4, -2), c + Vector2(0, 6),
				c + Vector2(4, -10), c + Vector2(8, 10)
			]), ink, 2.2, true)
		"moon":
			draw_arc(c, 12, -0.4, 2.6, 24, ink, 2.5, true)
		"anvil":
			draw_line(c + Vector2(-14, 0), c + Vector2(14, 0), ink, 4.0, true)
			draw_line(c + Vector2(0, 0), c + Vector2(0, 12), ink, 3.0, true)
			draw_line(c + Vector2(-8, 12), c + Vector2(8, 12), ink, 2.5, true)
		"crown":
			_draw_crown(c, mini(w, h) * 0.2, ink)
		"stag":
			_draw_stag(c, mini(w, h) * 0.2, ink)
		"raven":
			_draw_raven(c, mini(w, h) * 0.2, ink)
		"serpent":
			_draw_serpent(c, mini(w, h) * 0.2, ink)
		"sun":
			_draw_sun(c, mini(w, h) * 0.19, ink)
		"helm":
			_draw_helm(c, mini(w, h) * 0.2, ink)
		"fleur":
			_draw_fleur(c, mini(w, h) * 0.2, ink)
		"griffin":
			_draw_griffin(c, mini(w, h) * 0.2, ink)
		_:
			_draw_star(c, mini(w, h) * 0.14, ink)


func _shield_points(w: float, h: float) -> PackedVector2Array:
	var cx := w * 0.5
	match shield_id:
		"french":
			return PackedVector2Array([Vector2(w * 0.1, h * 0.12), Vector2(w * 0.9, h * 0.12), Vector2(w * 0.88, h * 0.68), Vector2(cx, h * 0.94), Vector2(w * 0.12, h * 0.68)])
		"kite":
			return PackedVector2Array([Vector2(cx, h * 0.05), Vector2(w * 0.84, h * 0.18), Vector2(w * 0.74, h * 0.64), Vector2(cx, h * 0.98), Vector2(w * 0.26, h * 0.64), Vector2(w * 0.16, h * 0.18)])
		"round":
			var points := PackedVector2Array()
			for i in 32:
				points.append(Vector2(cx, h * 0.5) + Vector2.from_angle(float(i) * TAU / 32.0) * Vector2(w * 0.4, h * 0.42))
			return points
		"banner":
			return PackedVector2Array([Vector2(w * 0.14, h * 0.08), Vector2(w * 0.86, h * 0.08), Vector2(w * 0.86, h * 0.9), Vector2(cx, h * 0.72), Vector2(w * 0.14, h * 0.9)])
		"dwarven":
			return PackedVector2Array([Vector2(w * 0.24, h * 0.08), Vector2(w * 0.76, h * 0.08), Vector2(w * 0.92, h * 0.3), Vector2(w * 0.76, h * 0.72), Vector2(cx, h * 0.94), Vector2(w * 0.24, h * 0.72), Vector2(w * 0.08, h * 0.3)])
		_:
			return PackedVector2Array([Vector2(cx, h * 0.06), Vector2(w * 0.88, h * 0.18), Vector2(w * 0.88, h * 0.55), Vector2(cx, h * 0.94), Vector2(w * 0.12, h * 0.55), Vector2(w * 0.12, h * 0.18)])


func _scaled_points(points: PackedVector2Array, center: Vector2, scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + (point - center) * scale)
	return result


func _draw_vector_charge(c: Vector2, extent: float) -> bool:
	return false


func _draw_pattern(inner: PackedVector2Array, w: float, h: float, cx: float, bright: Color, deep: Color) -> void:
	match pattern_id:
		"per_pale":
			draw_colored_polygon(_clip_half(inner, 0, cx, true), bright)
		"per_fess":
			draw_colored_polygon(_clip_half(inner, 1, h * 0.48, true), bright)
		"quarterly":
			draw_colored_polygon(_clip_half(_clip_half(inner, 0, cx, true), 1, h * 0.48, false), bright)
			draw_colored_polygon(_clip_half(_clip_half(inner, 0, cx, false), 1, h * 0.48, true), bright)
		"chevron":
			_draw_clipped_polygon(PackedVector2Array([
				Vector2(w * 0.18, h * 0.58), Vector2(cx, h * 0.26), Vector2(w * 0.82, h * 0.58),
				Vector2(w * 0.74, h * 0.68), Vector2(cx, h * 0.43), Vector2(w * 0.26, h * 0.68),
			]), inner, bright)
		"bend":
			_draw_clipped_polygon(PackedVector2Array([
				Vector2(w * 0.08, h * 0.08), Vector2(w * 0.2, h * 0.02),
				Vector2(w * 0.92, h * 0.82), Vector2(w * 0.8, h * 0.9),
			]), inner, bright)
		"bend_sinister":
			_draw_clipped_polygon(PackedVector2Array([
				Vector2(w * 0.8, h * 0.02), Vector2(w * 0.92, h * 0.08),
				Vector2(w * 0.2, h * 0.9), Vector2(w * 0.08, h * 0.82),
			]), inner, bright)
		"cross_field":
			_draw_clipped_polygon(PackedVector2Array([Vector2(cx - w * 0.06, 0), Vector2(cx + w * 0.06, 0), Vector2(cx + w * 0.06, h), Vector2(cx - w * 0.06, h)]), inner, bright)
			_draw_clipped_polygon(PackedVector2Array([Vector2(0, h * 0.38), Vector2(w, h * 0.38), Vector2(w, h * 0.5), Vector2(0, h * 0.5)]), inner, bright)
		"saltire":
			_draw_clipped_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.1, 0), Vector2(w, h * 0.88), Vector2(w, h), Vector2(w * 0.9, h)]), inner, bright)
			_draw_clipped_polygon(PackedVector2Array([Vector2(w * 0.9, 0), Vector2(w, 0), Vector2(w * 0.1, h), Vector2(0, h), Vector2(0, h * 0.88)]), inner, bright)
		"chief":
			_draw_clipped_polygon(PackedVector2Array([Vector2(0, h * 0.08), Vector2(w, h * 0.08), Vector2(w, h * 0.34), Vector2(0, h * 0.34)]), inner, bright)
		"base":
			_draw_clipped_polygon(PackedVector2Array([Vector2(0, h * 0.62), Vector2(w, h * 0.62), Vector2(w, h), Vector2(0, h)]), inner, bright)
		"bordure":
			var closed := inner.duplicate()
			closed.append(inner[0])
			draw_polyline(closed, bright, maxf(4.0, w * 0.06), true)


func _draw_clipped_polygon(shape: PackedVector2Array, mask: PackedVector2Array, color: Color) -> void:
	for polygon in Geometry2D.intersect_polygons(shape, mask):
		if polygon.size() >= 3:
			draw_colored_polygon(polygon, color)


func _clip_half(points: PackedVector2Array, axis: int, threshold: float, keep_greater: bool) -> PackedVector2Array:
	var output := PackedVector2Array()
	if points.is_empty():
		return output
	for i in points.size():
		var current := points[i]
		var previous := points[(i - 1 + points.size()) % points.size()]
		var current_value := current.x if axis == 0 else current.y
		var previous_value := previous.x if axis == 0 else previous.y
		var current_inside := current_value >= threshold if keep_greater else current_value <= threshold
		var previous_inside := previous_value >= threshold if keep_greater else previous_value <= threshold
		if current_inside != previous_inside:
			var denominator := current_value - previous_value
			var t := 0.0 if is_zero_approx(denominator) else (threshold - previous_value) / denominator
			output.append(previous.lerp(current, t))
		if current_inside:
			output.append(current)
	return output


func _draw_lion(c: Vector2, r: float, col: Color) -> void:
	# Одноцветная геральдическая львиная голова в профиль.
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.72, r * 0.6), c + Vector2(-r * 0.54, r * 0.18),
		c + Vector2(-r * 0.76, -r * 0.08), c + Vector2(-r * 0.44, -r * 0.28),
		c + Vector2(-r * 0.54, -r * 0.66), c + Vector2(-r * 0.14, -r * 0.55),
		c + Vector2(0, -r * 0.82), c + Vector2(r * 0.2, -r * 0.5),
		c + Vector2(r * 0.52, -r * 0.4), c + Vector2(r * 0.86, -r * 0.16),
		c + Vector2(r * 0.52, r * 0.02), c + Vector2(r * 0.78, r * 0.2),
		c + Vector2(r * 0.38, r * 0.24), c + Vector2(r * 0.26, r * 0.64),
		c + Vector2(-r * 0.08, r * 0.48), c + Vector2(-r * 0.38, r * 0.76),
	]), col)
	var cut := fill_color.darkened(0.08)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.12, -r * 0.28), c + Vector2(r * 0.3, -r * 0.34),
		c + Vector2(r * 0.28, -r * 0.18),
	]), cut)
	draw_line(c + Vector2(r * 0.32, r * 0.08), c + Vector2(r * 0.62, r * 0.14), cut, maxf(2.0, r * 0.07), true)


func draw_triangle(c: Vector2, r: float, col: Color) -> void:
	_draw_triangle_mark(c, r, col)


func _draw_wolf(c: Vector2, r: float, col: Color) -> void:
	var head := PackedVector2Array([
		c + Vector2(-r * 0.55, -r * 0.65), c + Vector2(-r * 0.28, -r * 0.25),
		c + Vector2(-r * 0.42, r * 0.22), c + Vector2(0, r * 0.68),
		c + Vector2(r * 0.42, r * 0.22), c + Vector2(r * 0.28, -r * 0.25),
		c + Vector2(r * 0.55, -r * 0.65), c + Vector2(0, -r * 0.4),
	])
	draw_colored_polygon(head, col)
	draw_circle(c + Vector2(-r * 0.17, -r * 0.05), r * 0.055, Color("15191F"))
	draw_circle(c + Vector2(r * 0.17, -r * 0.05), r * 0.055, Color("15191F"))


func _draw_crown(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(-r, r * 0.45), c + Vector2(-r, -r * 0.45),
		c + Vector2(-r * 0.45, 0), c + Vector2(0, -r * 0.75),
		c + Vector2(r * 0.45, 0), c + Vector2(r, -r * 0.45),
		c + Vector2(r, r * 0.45),
	])
	draw_colored_polygon(pts, col)
	draw_line(c + Vector2(-r, r * 0.55), c + Vector2(r, r * 0.55), col, 3.0, true)


func _draw_stag(c: Vector2, r: float, col: Color) -> void:
	draw_line(c + Vector2(0, r * 0.65), c + Vector2(0, -r * 0.35), col, 4.0, true)
	for side in [-1.0, 1.0]:
		var base := c + Vector2(side * r * 0.12, -r * 0.2)
		draw_line(base, c + Vector2(side * r * 0.72, -r * 0.72), col, 3.0, true)
		draw_line(c + Vector2(side * r * 0.38, -r * 0.43), c + Vector2(side * r * 0.6, -r * 0.2), col, 2.2, true)
		draw_line(c + Vector2(side * r * 0.52, -r * 0.56), c + Vector2(side * r * 0.72, -r * 0.42), col, 2.2, true)
	draw_circle(c + Vector2(0, r * 0.12), r * 0.33, col)


func _draw_raven(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r, 0), c + Vector2(-r * 0.2, -r * 0.42),
		c + Vector2(0, -r * 0.1), c + Vector2(r * 0.22, -r * 0.42),
		c + Vector2(r, 0), c + Vector2(r * 0.22, r * 0.26),
		c + Vector2(0, r * 0.72), c + Vector2(-r * 0.22, r * 0.26),
	]), col)


func _draw_serpent(c: Vector2, r: float, col: Color) -> void:
	draw_arc(c + Vector2(0, -r * 0.22), r * 0.48, -2.2, 1.2, 24, col, 4.0, true)
	draw_arc(c + Vector2(0, r * 0.38), r * 0.48, 0.9, 4.2, 24, col, 4.0, true)
	_draw_triangle_mark(c + Vector2(r * 0.42, -r * 0.48), r * 0.22, col)


func _draw_sun(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r * 0.48, col)
	for i in 12:
		var dir := Vector2.from_angle(float(i) * TAU / 12.0)
		draw_line(c + dir * r * 0.58, c + dir * r, col, 2.5, true)


func _draw_helm(c: Vector2, r: float, col: Color) -> void:
	draw_arc(c, r * 0.72, PI, TAU, 24, col, 4.0, true)
	draw_line(c + Vector2(-r * 0.72, 0), c + Vector2(-r * 0.5, r * 0.7), col, 4.0, true)
	draw_line(c + Vector2(r * 0.72, 0), c + Vector2(r * 0.5, r * 0.7), col, 4.0, true)
	draw_line(c + Vector2(-r * 0.5, r * 0.15), c + Vector2(r * 0.5, r * 0.15), col, 3.0, true)
	draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.68), col, 3.0, true)


func _draw_fleur(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(0, -r * 0.38), r * 0.3, col)
	draw_circle(c + Vector2(-r * 0.38, -r * 0.05), r * 0.28, col)
	draw_circle(c + Vector2(r * 0.38, -r * 0.05), r * 0.28, col)
	draw_line(c + Vector2(0, -r * 0.2), c + Vector2(0, r * 0.75), col, 4.0, true)
	draw_line(c + Vector2(-r * 0.55, r * 0.35), c + Vector2(r * 0.55, r * 0.35), col, 3.0, true)


func _draw_griffin(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.1, r * 0.12), r * 0.35, col)
	draw_polyline(PackedVector2Array([
		c + Vector2(-r * 0.1, 0), c + Vector2(-r * 0.72, -r * 0.72),
		c + Vector2(r * 0.1, -r * 0.4), c + Vector2(r * 0.62, -r * 0.62),
		c + Vector2(r * 0.28, -r * 0.16),
	]), col, 3.5, true)
	draw_line(c + Vector2(-r * 0.25, r * 0.35), c + Vector2(-r * 0.45, r), col, 3.0, true)
	draw_line(c + Vector2(r * 0.08, r * 0.35), c + Vector2(r * 0.28, r), col, 3.0, true)


func _draw_triangle_mark(c: Vector2, r: float, col: Color) -> void:
	var tri := PackedVector2Array([
		c + Vector2(0, -r),
		c + Vector2(r * 0.9, r * 0.7),
		c + Vector2(-r * 0.9, r * 0.7),
	])
	draw_colored_polygon(tri, col)


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 5:
		var a1 := -PI / 2.0 + float(i) * TAU / 5.0
		var a2 := a1 + TAU / 10.0
		pts.append(c + Vector2(cos(a1), sin(a1)) * r)
		pts.append(c + Vector2(cos(a2), sin(a2)) * r * 0.45)
	draw_colored_polygon(pts, col)
