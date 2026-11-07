class_name PulleyPart
extends Part
## Poulie : fixe, solide, et point de passage d'une corde.

const RADIUS := 16.0

var spin := 0.0


func _build() -> void:
	var body := make_static()
	add_disc(body, RADIUS)
	add_visual(body, paint)


func can_tie() -> bool:
	return false


func icon_scale() -> float:
	return 1.0


func paint(c: CanvasItem) -> void:
	c.draw_circle(Vector2.ZERO, RADIUS, STEEL)
	c.draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, INK, 2.0)
	c.draw_arc(Vector2.ZERO, RADIUS - 5.0, 0.0, TAU, 28, INK, 1.5)
	for i in 3:
		var a := spin + i * TAU / 3.0
		c.draw_line(Vector2.ZERO, Vector2.from_angle(a) * (RADIUS - 5.0), INK, 2.0)
	c.draw_circle(Vector2.ZERO, 3.0, INK)
