class_name FunnelPart
extends Part
## Entonnoir : deux parois en V qui rassemblent ce qui tombe vers une ouverture assez large pour
## le boulet.

const TOP := 140.0
const OPENING := 56.0
const HEIGHT := 70.0
const WALL := 8.0


func _build() -> void:
	var body := make_static(0.05, 0.2)
	for side: float in [-1.0, 1.0]:
		add_poly(body, _wall(side))
	add_visual(body, paint)


## Paroi gauche (-1) ou droite (1), en quadrilatère convexe.
func _wall(side: float) -> PackedVector2Array:
	var top := Vector2(side * TOP / 2.0, -HEIGHT / 2.0)
	var bottom := Vector2(side * OPENING / 2.0, HEIGHT / 2.0)
	return PackedVector2Array([top, top + Vector2(side * WALL, 0), bottom + Vector2(side * WALL, 0), bottom])


func rotate_step() -> float:
	return 15.0


func icon_scale() -> float:
	return 0.45


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Ouverture de %d px : le boulet y passe.") % OPENING)
	return lines


func paint(c: CanvasItem) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(-TOP / 2.0, -HEIGHT / 2.0), Vector2(TOP / 2.0, -HEIGHT / 2.0),
		Vector2(OPENING / 2.0, HEIGHT / 2.0), Vector2(-OPENING / 2.0, HEIGHT / 2.0),
	]), Color(1, 1, 1, 0.06))
	for side: float in [-1.0, 1.0]:
		poly(c, _wall(side), Color("b8c4d4"))
	c.draw_line(Vector2(-OPENING / 2.0, HEIGHT / 2.0), Vector2(OPENING / 2.0, HEIGHT / 2.0),
			Color(1, 1, 1, 0.25), 1.0)
