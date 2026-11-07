class_name SpringPart
extends Part
## Ressort : renvoie tout objet à vitesse fixe le long de son axe, quelle que soit sa masse.

const SIZE := Vector2(90, 18)
const SPEED := 820.0

var _flash := 0.0


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)
	add_sensor(Vector2(SIZE.x - 6.0, 12.0), Vector2(0, -SIZE.y / 2.0 - 5.0), _on_enter)


func rotate_step() -> float:
	return 15.0


func icon_scale() -> float:
	return 0.5


func is_animated() -> bool:
	return true


func _on_enter(node: Node2D) -> void:
	if node is RigidBody2D:
		var up := Vector2.UP.rotated(global_rotation)
		var rb: RigidBody2D = node
		rb.linear_velocity += up * (SPEED - rb.linear_velocity.dot(up))
		_flash = anim + 0.15


func paint(c: CanvasItem) -> void:
	var lift := -4.0 if anim < _flash else 0.0
	box(c, Rect2(-SIZE.x / 2.0, 0, SIZE.x, SIZE.y / 2.0), STEEL)
	box(c, Rect2(-SIZE.x / 2.0, -SIZE.y / 2.0 + lift, SIZE.x, 6.0), Color("5dd39e"))
	for x in [-30.0, 0.0, 30.0]:
		c.draw_line(Vector2(x - 6, -2 + lift), Vector2(x + 6, 3), INK, 2.0)
