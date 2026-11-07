class_name CratePart
extends Part

const SIZE := Vector2(44, 44)


func _build() -> void:
	var body := make_rigid(2.0, 0.05)
	add_box(body, SIZE)
	add_visual(body, paint)


func paint(c: CanvasItem) -> void:
	var r := Rect2(-SIZE / 2.0, SIZE)
	box(c, r, Color("b07a3f"))
	c.draw_line(r.position, r.end, INK, 2.0)
	c.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), INK, 2.0)
