class_name BasketPart
extends Part
## Panier : objectif rempli quand un objet accepté y reste assez longtemps.

const WIDTH := 150.0
const HEIGHT := 84.0
const WALL := 10.0
const HOLD_TIME := 0.5

var inside: Area2D
var held := 0.0


func _build() -> void:
	var body := make_static()
	var half := Vector2(WIDTH, HEIGHT) / 2.0
	add_box(body, Vector2(WIDTH, WALL), Vector2(0, half.y - WALL / 2.0))
	add_box(body, Vector2(WALL, HEIGHT), Vector2(-half.x + WALL / 2.0, 0))
	add_box(body, Vector2(WALL, HEIGHT), Vector2(half.x - WALL / 2.0, 0))
	add_visual(body, paint)
	inside = add_sensor(Vector2(WIDTH - WALL * 2.0, HEIGHT - WALL - 6.0), Vector2(0, WALL / 2.0))


func _physics_process(delta: float) -> void:
	var has_target := false
	for node in inside.get_overlapping_bodies():
		var part := Part.from_body(node)
		if node is RigidBody2D and part != null and part.gear_radius() == 0.0 and _accepts(part):
			has_target = true
			break
	held = held + delta if has_target else 0.0


func is_satisfied() -> bool:
	return held >= HOLD_TIME


func rotate_step() -> float:
	return 0.0


func icon_scale() -> float:
	return 0.45


func _accepts(part: Part) -> bool:
	var accepted: Array = entry.get("accepts", [])
	return accepted.is_empty() or accepted.has(part.kind)


func paint(c: CanvasItem) -> void:
	var half := Vector2(WIDTH, HEIGHT) / 2.0
	c.draw_rect(Rect2(-half, Vector2(WIDTH, HEIGHT)), Color(GOLD, 0.12))
	box(c, Rect2(-half.x, half.y - WALL, WIDTH, WALL), GOLD)
	box(c, Rect2(-half.x, -half.y, WALL, HEIGHT), GOLD)
	box(c, Rect2(half.x - WALL, -half.y, WALL, HEIGHT), GOLD)
