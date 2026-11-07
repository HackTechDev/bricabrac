class_name PlankPart
extends Part
## Planche fixe : en bois pour le joueur, en acier pour les éléments du décor.

const THICKNESS := 14.0


func _build() -> void:
	var body := make_static()
	add_box(body, Vector2(_length(), THICKNESS))
	add_visual(body, paint)


func rotate_step() -> float:
	return 15.0


func icon_scale() -> float:
	return 0.3


func rope_anchor(point: Vector2) -> Vector2:
	var limit := _length() / 2.0 - 4.0
	return Vector2(snappedf(clampf(main_body.to_local(point).x, -limit, limit), 10.0), 0)


func paint(c: CanvasItem) -> void:
	var l := _length()
	var locked: bool = entry.get("locked", false)
	box(c, Rect2(-l / 2.0, -THICKNESS / 2.0, l, THICKNESS), STEEL if locked else WOOD)
	if locked:
		var x := -l / 2.0 + 12.0
		while x < l / 2.0:
			c.draw_circle(Vector2(x, 0), 2.0, INK)
			x += 40.0


func _length() -> float:
	return entry.get("len", 160.0)
