class_name GearPart
extends Part
## Engrenage et moteur. Une roue tourne sur un axe fixe ; deux roues dont les dents se touchent
## engrènent : elles tournent en sens inverse, à des vitesses inversement proportionnelles à leurs
## rayons. Le plateau résout ces liaisons à chaque image (Godot n'a pas de joint d'engrenage).
##
## « gear » : roue avec un bras qui balaie et pousse les objets ; R oriente le bras.
## « motor » : socle et petite roue motrice, entraînée quand son canal est allumé (0 : toujours).
## Miroir : sens de rotation du moteur.

const GEAR_RADIUS := 40.0
const MOTOR_RADIUS := 30.0
const TOOTH := 5.0
const ARM := Vector2(78, 12)
const MOTOR_SPEED := 2.5
const HOUSING := Vector2(54, 30)

var wheel: RigidBody2D


func _build() -> void:
	var axle := make_static()
	# Le socle n'arrête pas les bras des roues voisines, mais arrête le reste.
	axle.collision_layer = Part.LAYER_GEARS
	axle.collision_mask = 0
	if is_motor():
		add_box(axle, HOUSING, Vector2(0, gear_radius() * 0.6))
		add_visual(axle, _paint_housing)
	# Sans gravité : un bras ne fait pas pencher sa roue comme un balancier.
	wheel = make_rigid(1.0, 0.1, 0.8, 0.0)
	wheel.collision_layer = Part.LAYER_GEARS
	wheel.collision_mask = Part.LAYER_WORLD
	wheel.linear_damp = 0.0
	wheel.angular_damp = 0.0
	add_disc(wheel, gear_radius() - TOOTH)
	if not is_motor():
		add_box(wheel, ARM, Vector2(ARM.x / 2.0, 0))
	add_visual(wheel, _paint_wheel)
	if running:
		var joint := PinJoint2D.new()
		add_child(joint)
		joint.node_a = joint.get_path_to(axle)
		joint.node_b = joint.get_path_to(wheel)


func is_motor() -> bool:
	return kind == "motor"


func gear_radius() -> float:
	return MOTOR_RADIUS if is_motor() else GEAR_RADIUS


func gear_body() -> RigidBody2D:
	return wheel


## Vitesse imposée par le moteur, en rad/s ; NAN si la roue tourne librement.
func drive_speed() -> float:
	return MOTOR_SPEED * dir if is_motor() and powered else NAN


func collision_layer() -> int:
	return Part.LAYER_GEARS


func collision_mask() -> int:
	return Part.LAYER_WORLD


func rotate_step() -> float:
	return 0.0 if is_motor() else 45.0


func can_flip() -> bool:
	return is_motor()


func channel_range() -> Vector2i:
	return Vector2i(0, 3) if is_motor() else Vector2i(-1, -1)


func can_tie() -> bool:
	return false


func icon_scale() -> float:
	return 0.45


func describe() -> PackedStringArray:
	var lines := super()
	if is_motor():
		lines.append("Tourne dans le sens %s." % ("horaire" if dir > 0 else "antihoraire"))
	var count := board.gear_neighbors(self).size() if board != null else 0
	lines.append("Engrène avec %d roue(s)." % count if count > 0 else "N'engrène avec aucune roue.")
	return lines


func paint_icon(c: CanvasItem) -> void:
	if is_motor():
		_paint_housing(c)
	_paint_wheel(c)


func _paint_wheel(c: CanvasItem) -> void:
	var r := gear_radius()
	var teeth := int(r / 4.0)
	var outline := PackedVector2Array()
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4)
		var radius := r if i % 4 < 2 else r - TOOTH * 1.6
		outline.append(Vector2.from_angle(a) * radius)
	var fill := Color("d9a441") if is_motor() else Color("b8c2cf")
	if not is_motor():
		box(c, Rect2(Vector2(0, -ARM.y / 2.0), ARM), WOOD)
	poly(c, outline, fill)
	c.draw_arc(Vector2.ZERO, r * 0.45, 0.0, TAU, 24, INK, 2.0)
	c.draw_circle(Vector2.ZERO, 5.0, INK)


func _paint_housing(c: CanvasItem) -> void:
	var r := Rect2(Vector2(-HOUSING.x / 2.0, gear_radius() * 0.6 - HOUSING.y / 2.0), HOUSING)
	box(c, r, Color("47525f"))
	var arrow_y := r.end.y - 8.0
	c.draw_line(Vector2(-12, arrow_y), Vector2(12, arrow_y), Color.WHITE, 2.0)
	c.draw_line(Vector2(12 * dir, arrow_y), Vector2(6 * dir, arrow_y - 5), Color.WHITE, 2.0)
	paint_channel(c, Vector2(-HOUSING.x / 2.0 + 10.0, r.position.y + 10.0))
