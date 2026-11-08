class_name PortalPart
extends Part
## Portail : un objet qui y entre ressort aussitôt par l'autre portail du même canal, à la même
## vitesse. Si les deux portails n'ont pas la même orientation, la trajectoire tourne d'autant.
## Un objet qui vient d'arriver est ignoré jusqu'à ce qu'il ait quitté le portail de sortie.

const SIZE := Vector2(22, 96)
const OPENING := Vector2(14, 84)

var area: Area2D


func _build() -> void:
	var frame := make_static()
	# Le cadre se sélectionne et occupe de la place, mais rien ne le heurte.
	frame.collision_layer = 0
	frame.collision_mask = 0
	add_box(frame, SIZE)
	add_visual(frame, paint)
	area = add_sensor(OPENING, Vector2.ZERO, _on_enter)
	if area != null:
		area.body_exited.connect(_on_exit)


func rotate_step() -> float:
	return 45.0


## Le canal ne met rien en marche : il désigne le portail de sortie.
func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func can_tie() -> bool:
	return false


func icon_scale() -> float:
	return 0.55


func describe() -> PackedStringArray:
	var lines := super()
	var exit := partner() if board != null else null
	lines.append(Lang.t("Relié à un autre portail du canal %d.") % channel if exit != null
			else Lang.t("Sans autre portail du canal %d, il ne fait rien.") % channel)
	return lines


## Portail de sortie : le suivant du même canal, dans l'ordre de pose.
func partner() -> PortalPart:
	var same: Array[PortalPart] = []
	for part in board.parts:
		if part is PortalPart and part.channel == channel:
			same.append(part)
	if same.size() < 2:
		return null
	return same[(same.find(self) + 1) % same.size()]


func _on_enter(node: Node2D) -> void:
	if not (node is RigidBody2D) or node.has_meta("portal_lock"):
		return
	var exit := partner()
	if exit != null:
		_send.call_deferred(node as RigidBody2D, exit)


func _on_exit(node: Node2D) -> void:
	if node.has_meta("portal_lock") and node.get_meta("portal_lock") == self:
		node.remove_meta("portal_lock")


func _send(body: RigidBody2D, exit: PortalPart) -> void:
	if not is_instance_valid(body) or not is_instance_valid(exit):
		return
	var turn := exit.global_rotation - global_rotation
	# On garde le décalage le long de l'ouverture, on ressort au milieu de son épaisseur.
	var offset := to_local(body.global_position)
	offset.x = 0.0
	var target := exit.to_global(offset)
	body.set_meta("portal_lock", exit)
	var xform := Transform2D(body.global_rotation + turn, target)
	var rid := body.get_rid()
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, xform)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY,
			body.linear_velocity.rotated(turn))
	body.global_transform = xform
	board.sfx.play("tick")


func paint(c: CanvasItem) -> void:
	var col := CHANNEL_COLORS[channel]
	var ring := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		ring.append(Vector2(cos(a) * SIZE.x / 2.0, sin(a) * SIZE.y / 2.0))
		inner.append(Vector2(cos(a) * OPENING.x / 2.0, sin(a) * OPENING.y / 2.0))
	poly(c, ring, col)
	c.draw_colored_polygon(inner, Color("0b1424"))
	for k in 3:
		var f := 0.3 + 0.2 * k
		var swirl := PackedVector2Array()
		for i in 17:
			var a := TAU * i / 16.0
			swirl.append(Vector2(cos(a) * OPENING.x / 2.0 * f, sin(a) * OPENING.y / 2.0 * f))
		c.draw_polyline(swirl, col.lerp(Color.WHITE, 0.3), 1.5)
	paint_channel(c, Vector2(0, -SIZE.y / 2.0 - 10.0))
