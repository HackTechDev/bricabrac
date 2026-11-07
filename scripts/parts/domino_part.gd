class_name DominoPart
extends Part

const SIZE := Vector2(12, 60)


func _build() -> void:
	var body := make_rigid(0.6, 0.05, 0.5)
	add_box(body, SIZE)
	add_visual(body, paint)


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-SIZE / 2.0, SIZE), Color("efe9dc"))
	c.draw_line(Vector2(-6, 0), Vector2(6, 0), INK, 2.0)


func icon_scale() -> float:
	return 0.8
