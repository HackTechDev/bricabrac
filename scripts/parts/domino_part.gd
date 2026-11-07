class_name DominoPart
extends Part

const SIZE := Vector2(12, 60)


func _build() -> void:
	var body := make_rigid(0.6, 0.05, 0.5)
	add_box(body, SIZE)
	add_visual(body, paint)


func impact_sound() -> String:
	return "wood"


## Attache vers le bout le plus proche, pour que la corde puisse le faire basculer.
func rope_anchor(point: Vector2) -> Vector2:
	var side := signf(main_body.to_local(point).y)
	return Vector2(0, (SIZE.y / 2.0 - 6.0) * (side if side != 0.0 else -1.0))


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-SIZE / 2.0, SIZE), Color("efe9dc"))
	c.draw_line(Vector2(-6, 0), Vector2(6, 0), INK, 2.0)


func icon_scale() -> float:
	return 0.8
