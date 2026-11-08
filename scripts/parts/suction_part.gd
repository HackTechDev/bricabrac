class_name SuctionPart
extends Part
## Ventouse : retient le premier objet qui touche sa coupelle, en le laissant pivoter autour du
## point de contact. Canal 0 : elle ne lâche jamais ; canal 1 à 3 : elle lâche quand il s'allume.

const BASE := Vector2(44, 14)
const CUP_RADIUS := 18.0
## Point d'accroche, au sommet de la coupelle, dans le repère de la pièce.
const GRIP := Vector2(0, -BASE.y / 2.0 - CUP_RADIUS + 4.0)

var mount: StaticBody2D
var held: RigidBody2D
var _joint: PinJoint2D


func _build() -> void:
	mount = make_static(0.0, 1.0)
	add_box(mount, BASE)
	add_visual(mount, paint)
	add_sensor(Vector2(CUP_RADIUS * 2.0, 14.0), GRIP + Vector2(0, -4.0), _on_touch)


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func rotate_step() -> float:
	return 45.0


func icon_scale() -> float:
	return 0.7


func describe() -> PackedStringArray:
	var lines := super()
	lines.append("Retient pour toujours ce qui la touche." if channel == 0
			else "Retient ce qui la touche, et le lâche quand le canal %d s'allume." % channel)
	return lines


func _releases() -> bool:
	return channel != 0 and powered


func _on_touch(node: Node2D) -> void:
	if held != null or _releases() or not node is RigidBody2D:
		return
	_grab.call_deferred(node as RigidBody2D)


func _grab(body: RigidBody2D) -> void:
	if held != null or not is_instance_valid(body) or _releases():
		return
	held = body
	_joint = PinJoint2D.new()
	_joint.position = GRIP
	_joint.softness = 0.0
	add_child(_joint)
	_joint.node_a = _joint.get_path_to(mount)
	_joint.node_b = _joint.get_path_to(body)
	board.sfx.play("plate")
	refresh()


func on_powered() -> void:
	if _releases() and _joint != null:
		_joint.queue_free()
		_joint = null
		board.sfx.play("pop", 0.4)
		refresh()


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-BASE / 2.0, BASE), STEEL)
	var cup := PackedVector2Array()
	var centre := Vector2(0, -BASE.y / 2.0)
	for i in 17:
		var a := PI + PI * i / 16.0
		cup.append(centre + Vector2(cos(a) * CUP_RADIUS, sin(a) * (CUP_RADIUS - 4.0)))
	var col := Color("e0566b") if _joint != null else Color("f07f8f")
	poly(c, cup, col)
	c.draw_line(centre + Vector2(-CUP_RADIUS + 3, -2), centre + Vector2(CUP_RADIUS - 3, -2), Color(1, 1, 1, 0.4), 2.0)
	paint_channel(c, Vector2(0, 0))
