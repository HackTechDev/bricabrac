class_name SwitchPart
extends Part
## Interrupteur à bascule : chaque objet qui heurte son levier inverse l'état de son canal.
## Il éteint aussi bien qu'il allume. Un objet qui rebondit sur le levier ne compte qu'une fois.

const BASE := Vector2(60, 16)
const SAME_BODY_DELAY := 1.0

var _last_hit := {}


func _build() -> void:
	var body := make_static()
	add_box(body, BASE, Vector2(0, BASE.y / 2.0))
	add_visual(body, paint)
	add_sensor(Vector2(44, 40), Vector2(0, -20), _on_enter)


func rotate_step() -> float:
	return 90.0


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func icon_scale() -> float:
	return 0.7


func is_animated() -> bool:
	return true


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Allumé") if powered else Lang.t("Éteint"))
	return lines


func _on_enter(node: Node2D) -> void:
	if not node is RigidBody2D:
		return
	var id := node.get_instance_id()
	if anim - _last_hit.get(id, -10.0) >= SAME_BODY_DELAY:
		board.toggle_channel.call_deferred(channel)
	_last_hit[id] = anim


func on_powered() -> void:
	board.sfx.play("plate")


func paint(c: CanvasItem) -> void:
	var lean := 0.5 if powered else -0.5
	var tip := Vector2(0, 2).lerp(Vector2(0, -34).rotated(lean), 1.0)
	c.draw_line(Vector2(0, 2), tip, INK, 8.0)
	c.draw_line(Vector2(0, 2), tip, STEEL, 5.0)
	c.draw_circle(tip, 7.0, Accessibility.channel_color(channel) if powered else Color("56606f"))
	c.draw_arc(tip, 7.0, 0.0, TAU, 20, INK, 2.0)
	box(c, Rect2(-BASE.x / 2.0, 0, BASE.x, BASE.y), STEEL)
	paint_channel(c, Vector2(BASE.x / 2.0 - 12.0, BASE.y / 2.0))
