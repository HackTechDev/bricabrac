class_name FlashlightPart
extends Part
## Lampe de poche : son faisceau éclaire le grenier plongé dans le noir. Canal 0 : allumée dès
## le départ ; canal 1 à 3 : s'allume avec son canal. Elle pivote par crans de 15°.

const SIZE := Vector2(54, 22)
## Portée et demi-ouverture du faisceau.
const RANGE := 460.0
const HALF_ANGLE := 0.42
const LENS := Vector2(SIZE.x / 2.0 + 4.0, 0)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func rotate_step() -> float:
	return 15.0


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func icon_scale() -> float:
	return 0.8


func on_powered() -> void:
	if running and powered:
		board.sfx.play("lamp")


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Éclaire jusqu'à %d px devant elle.") % int(RANGE))
	return lines


func light_sources() -> Array:
	if not powered:
		return []
	var origin := board.to_local(to_global(LENS))
	var forward := global_transform.basis_xform(Vector2.RIGHT).normalized()
	return [{"pos": origin, "dir": forward, "range": RANGE, "half": HALF_ANGLE}]


func paint(c: CanvasItem) -> void:
	var half := SIZE / 2.0
	# Hors du grenier, un cône pâle montre où elle éclaire ; dans le noir, le voile s'en charge.
	if powered and board != null and not board.is_dark():
		c.draw_colored_polygon(PackedVector2Array([LENS + Vector2(0, -9),
				LENS + Vector2.from_angle(-HALF_ANGLE) * 150.0, LENS + Vector2.from_angle(HALF_ANGLE) * 150.0,
				LENS + Vector2(0, 9)]), Color(GOLD, 0.12))
	box(c, Rect2(-half.x, -half.y + 3.0, SIZE.x - 12.0, SIZE.y - 6.0), Color("c0392b"))
	box(c, Rect2(half.x - 14.0, -half.y, 14.0, SIZE.y), STEEL)
	c.draw_line(Vector2(half.x, -half.y + 3.0), Vector2(half.x, half.y - 3.0),
			GOLD if powered else Color("56606f"), 4.0)
	box(c, Rect2(-8.0, -half.y, 10.0, 4.0), INK)
	paint_channel(c, Vector2(-14, 0))
