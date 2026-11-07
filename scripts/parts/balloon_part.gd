class_name BalloonPart
extends Part
## Ballon : monte tout seul, éclate sur les pointes.

const RADIUS := 22.0

var body: RigidBody2D
var popped := false


func _build() -> void:
	body = make_rigid(0.5, 0.3, 0.3, -0.35)
	body.linear_damp = 1.5
	add_disc(body, RADIUS)
	add_visual(body, paint)


func pop() -> void:
	if popped:
		return
	popped = true
	board.sfx.play("pop")
	solids.clear()
	visuals.clear()
	body.queue_free()


func is_satisfied() -> bool:
	return popped


func icon_scale() -> float:
	return 0.8


func paint(c: CanvasItem) -> void:
	var col := Color("ff6b6b")
	c.draw_line(Vector2(0, RADIUS), Vector2(4, RADIUS + 18), Color(1, 1, 1, 0.7), 1.5)
	c.draw_circle(Vector2.ZERO, RADIUS, col)
	c.draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, INK, 2.0)
	c.draw_circle(Vector2(-7, -8), 4.0, Color(1, 1, 1, 0.7))
