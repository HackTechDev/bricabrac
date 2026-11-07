class_name ConveyorPart
extends Part
## Tapis roulant : canal 0 = toujours en marche, sinon attend sa plaque.

const SIZE := Vector2(200, 22)
const SPEED := 170.0

var body: StaticBody2D


func _build() -> void:
	body = make_static()
	add_box(body, SIZE)
	add_visual(body, paint)
	on_powered()


func on_powered() -> void:
	if running and powered:
		body.constant_linear_velocity = Vector2.RIGHT.rotated(global_rotation) * SPEED * dir


func rotate_step() -> float:
	return 15.0


func can_flip() -> bool:
	return true


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.25


func paint(c: CanvasItem) -> void:
	var r := Rect2(-SIZE / 2.0, SIZE)
	c.draw_rect(r, Color("39424f"))
	c.draw_rect(r, INK, false, 2.0)
	var moving := powered and running
	var phase := fposmod(anim * SPEED * dir, 24.0) if moving else 0.0
	var x := -SIZE.x / 2.0 + phase
	while x < SIZE.x / 2.0 - 8.0:
		var tip := 7.0 * dir
		c.draw_line(Vector2(x, -6), Vector2(x + tip, 0), Color("c5ced9"), 2.0)
		c.draw_line(Vector2(x + tip, 0), Vector2(x, 6), Color("c5ced9"), 2.0)
		x += 24.0
	paint_channel(c, Vector2(0, 0))
