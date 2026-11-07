class_name FanPart
extends Part
## Ventilateur : force constante, donc très efficace sur le léger et sans effet sur le lourd.
## Le vent traverse les obstacles.

const BODY_SIZE := Vector2(36, 70)
const RANGE := 340.0
const WIND_WIDTH := 80.0
const FORCE := 620.0

var wind: Area2D


func _build() -> void:
	var body := make_static()
	add_box(body, BODY_SIZE)
	add_visual(body, paint)
	wind = add_sensor(Vector2(RANGE, WIND_WIDTH), Vector2((RANGE / 2.0 + 20.0) * dir, 0))


func _physics_process(_delta: float) -> void:
	if not powered or wind == null:
		return
	var axis := Vector2.RIGHT.rotated(global_rotation) * dir
	for node in wind.get_overlapping_bodies():
		if node is RigidBody2D:
			(node as RigidBody2D).apply_central_force(axis * FORCE)


func rotate_step() -> float:
	return 45.0


func can_flip() -> bool:
	return true


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.55


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-BODY_SIZE / 2.0, BODY_SIZE), STEEL)
	var spin := anim * 18.0 if powered else 0.0
	for i in 3:
		var h := sin(spin + i * TAU / 3.0) * 26.0
		c.draw_line(Vector2(10 * dir, 0), Vector2(14 * dir, h), INK, 5.0)
	if powered and running:
		for i in 4:
			var d := fposmod(anim * 220.0 + i * 70.0, RANGE)
			var y := -30.0 + i * 20.0
			c.draw_line(Vector2((30.0 + d) * dir, y), Vector2((54.0 + d) * dir, y),
					Color(1, 1, 1, 0.35 * (1.0 - d / RANGE)), 2.0)
	paint_channel(c, Vector2(-6 * dir, 0))
