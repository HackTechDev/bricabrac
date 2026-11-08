class_name PipePart
extends Part
## Coude de tuyau : un quart de cercle creux qui guide les billes et les renvoie à angle droit.
## Il entre par le haut et ressort sur le côté droit (à gauche en miroir).

const INNER := 30.0
const OUTER := 92.0
const WALL := 7.0
const SEGMENTS := 8
## Centre de l'arc (en haut à droite), placé pour que la pièce soit centrée sur sa position.
const CENTER := Vector2((OUTER + WALL) / 2.0, -(OUTER + WALL) / 2.0)


func _build() -> void:
	var body := make_static(0.05, 0.05)
	for radius: float in [INNER - WALL, OUTER]:
		for i in SEGMENTS:
			add_poly(body, _segment(radius, i))
	add_visual(body, paint)


## Morceau de paroi entre les rayons `radius` et `radius + WALL`, du i-ème huitième d'arc.
func _segment(radius: float, i: int) -> PackedVector2Array:
	var a0 := PI / 2.0 + PI / 2.0 * i / SEGMENTS
	var a1 := PI / 2.0 + PI / 2.0 * (i + 1) / SEGMENTS
	var points := PackedVector2Array()
	for a: float in [a0, a1]:
		points.append(_at(Vector2.from_angle(a) * radius))
	for a: float in [a1, a0]:
		points.append(_at(Vector2.from_angle(a) * (radius + WALL)))
	return points


func _at(offset: Vector2) -> Vector2:
	return Vector2((CENTER.x + offset.x) * dir, CENTER.y + offset.y)


func rotate_step() -> float:
	return 90.0


func can_flip() -> bool:
	return true


func icon_scale() -> float:
	return 0.5


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Ce qui entre par le haut ressort %s.") % (Lang.t("à droite") if dir > 0 else Lang.t("à gauche")))
	return lines


func paint(c: CanvasItem) -> void:
	var inside := PackedVector2Array()
	for i in SEGMENTS + 1:
		inside.append(_at(Vector2.from_angle(PI / 2.0 + PI / 2.0 * i / SEGMENTS) * OUTER))
	for i in range(SEGMENTS, -1, -1):
		inside.append(_at(Vector2.from_angle(PI / 2.0 + PI / 2.0 * i / SEGMENTS) * INNER))
	c.draw_colored_polygon(inside, Color(0.55, 0.75, 0.6, 0.18))
	for radius: float in [INNER - WALL, OUTER]:
		for i in SEGMENTS:
			c.draw_colored_polygon(_segment(radius, i), Color("5f9e6e"))
		var edge := PackedVector2Array()
		for i in SEGMENTS + 1:
			edge.append(_at(Vector2.from_angle(PI / 2.0 + PI / 2.0 * i / SEGMENTS) * (radius + WALL / 2.0)))
		c.draw_polyline(edge, INK, 1.5)
