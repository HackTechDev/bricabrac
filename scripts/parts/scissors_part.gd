class_name ScissorsPart
extends Part
## Ciseaux : quand leur canal s'allume, ils coupent toute corde qui passe entre leurs lames.
## Avec une minuterie, ils déclenchent un mécanisme à retardement.

const BASE := Vector2(44, 14)
## Zone des lames, au-dessus du socle, dans le repère de la pièce.
const BLADES := Rect2(-30, -64, 60, 56)

var closed := false


func _build() -> void:
	var body := make_static()
	add_box(body, BASE, Vector2(0, BASE.y / 2.0 - 4.0))
	add_visual(body, paint)


func on_powered() -> void:
	if not (running and powered) or closed:
		return
	closed = true
	var cut := 0
	for part in board.parts:
		if part is RopePart and _crosses(part as RopePart):
			(part as RopePart).cut()
			cut += 1
	board.sfx.play("snip" if cut > 0 else "tick")


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func rotate_step() -> float:
	return 45.0


func icon_scale() -> float:
	return 0.6


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Coupe les cordes qui passent entre ses lames."))
	return lines


## La corde traverse-t-elle la zone des lames ?
func _crosses(rope: RopePart) -> bool:
	var path := rope.points()
	for i in range(1, path.size()):
		var a := to_local(board.to_global(path[i - 1]))
		var b := to_local(board.to_global(path[i]))
		if BLADES.has_point(a) or BLADES.has_point(b):
			return true
		var corners := [BLADES.position, Vector2(BLADES.end.x, BLADES.position.y), BLADES.end,
				Vector2(BLADES.position.x, BLADES.end.y)]
		for k in 4:
			if Geometry2D.segment_intersects_segment(a, b, corners[k], corners[(k + 1) % 4]) != null:
				return true
	return false


func paint(c: CanvasItem) -> void:
	if not running:
		c.draw_rect(BLADES, Color(1, 1, 1, 0.05))
		c.draw_rect(BLADES, Color(1, 1, 1, 0.15), false, 1.0)
	var pivot := Vector2(0, -22)
	var spread := 0.05 if closed else 0.45
	for side: float in [-1.0, 1.0]:
		var tip := pivot + Vector2(0, -38).rotated(spread * side)
		var handle := pivot + Vector2(0, 16).rotated(-spread * side * 1.4)
		poly(c, PackedVector2Array([pivot + Vector2(-3, 0), tip, pivot + Vector2(3, 0)]), Color("dfe6ef"))
		c.draw_line(pivot, handle, INK, 3.0)
		c.draw_circle(handle, 5.0, CHANNEL_COLORS[channel])
		c.draw_arc(handle, 5.0, 0.0, TAU, 16, INK, 1.5)
	c.draw_circle(pivot, 3.0, INK)
	box(c, Rect2(Vector2(-BASE.x / 2.0, -4.0), BASE), STEEL)
	paint_channel(c, Vector2(BASE.x / 2.0 - 10.0, 3.0))
