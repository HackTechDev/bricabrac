class_name LampPart
extends Part
## Lampe : objectif allumé par son canal.

const SIZE := Vector2(30, 56)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func on_powered() -> void:
	if powered:
		board.sfx.play("lamp")


func light_sources() -> Array:
	return [{"pos": board.to_local(to_global(Vector2(0, -12))), "range": 150.0}] if powered else []


func is_satisfied() -> bool:
	return powered


func icon_scale() -> float:
	return 0.7


func paint(c: CanvasItem) -> void:
	if powered:
		c.draw_circle(Vector2(0, -12), 44.0, Color(GOLD, 0.22))
		c.draw_circle(Vector2(0, -12), 28.0, Color(GOLD, 0.35))
	c.draw_circle(Vector2(0, -12), 15.0, GOLD if powered else Color("56606f"))
	c.draw_arc(Vector2(0, -12), 15.0, 0.0, TAU, 24, INK, 2.0)
	box(c, Rect2(-15, 6, 30, 22), STEEL)
	paint_channel(c, Vector2(0, 17))
