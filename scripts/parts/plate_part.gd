class_name PlatePart
extends Part
## Plaque de pression : un objet qui la touche allume tout son canal. Elle n'éteint jamais :
## seul un interrupteur le peut.

const SIZE := Vector2(90, 14)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)
	add_sensor(Vector2(SIZE.x - 4.0, 10.0), Vector2(0, -SIZE.y / 2.0 - 3.0), _on_enter)


func rotate_step() -> float:
	return 15.0


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func icon_scale() -> float:
	return 0.55


func _on_enter(node: Node2D) -> void:
	if node is RigidBody2D and not powered:
		board.activate_channel.call_deferred(channel)


func on_powered() -> void:
	if powered:
		board.sfx.play("plate")


func paint(c: CanvasItem) -> void:
	var col := Accessibility.channel_color(channel) if powered else STEEL
	box(c, Rect2(-SIZE.x / 2.0, -SIZE.y / 2.0, SIZE.x, SIZE.y), col)
	paint_channel(c, Vector2(0, 0))
