class_name SpikesPart
extends Part
## Pointes : solides pour tout le monde, fatales pour les ballons.

const SIZE := Vector2(120, 26)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)
	add_sensor(Vector2(SIZE.x + 8.0, SIZE.y + 12.0), Vector2.ZERO, _on_enter)


func rotate_step() -> float:
	return 45.0


func icon_scale() -> float:
	return 0.4


func _on_enter(node: Node2D) -> void:
	var part := Part.from_body(node)
	if part is BalloonPart:
		(part as BalloonPart).pop()


func paint(c: CanvasItem) -> void:
	var half := SIZE / 2.0
	box(c, Rect2(-half.x, half.y - 8.0, SIZE.x, 8.0), STEEL)
	var n := 6
	var w := SIZE.x / n
	for i in n:
		var x := -half.x + i * w
		poly(c, PackedVector2Array([
			Vector2(x, half.y - 8.0), Vector2(x + w / 2.0, -half.y), Vector2(x + w, half.y - 8.0),
		]), Color("dfe6ef"))
