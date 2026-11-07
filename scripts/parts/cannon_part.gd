class_name CannonPart
extends Part
## Canon : tire une unique bille quand son canal s'allume.

const SPEED := 720.0
const SIZE := Vector2(76, 36)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func on_powered() -> void:
	if not (running and powered):
		return
	var axis := Vector2.RIGHT.rotated(global_rotation) * dir
	board.sfx.play("cannon")
	board.spawn({
		"kind": "ball",
		"pos": global_position + axis * (SIZE.x / 2.0 + 20.0),
		"vel": axis * SPEED,
	})


func rotate_step() -> float:
	return 15.0


func can_flip() -> bool:
	return true


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func icon_scale() -> float:
	return 0.6


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-SIZE / 2.0, SIZE), Color("47525f"))
	var mouth := Rect2(Vector2(SIZE.x / 2.0 - 12.0, -SIZE.y / 2.0 - 3.0), Vector2(12, SIZE.y + 6.0))
	if dir < 0:
		mouth.position.x = -SIZE.x / 2.0
	box(c, mouth, STEEL)
	paint_channel(c, Vector2(-8 * dir, 0))
