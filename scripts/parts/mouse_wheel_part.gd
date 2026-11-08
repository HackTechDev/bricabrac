class_name MouseWheelPart
extends GearPart
## Souris dans une roue : elle dort jusqu'à ce qu'un objet heurte sa roue ou que son canal
## s'allume. Réveillée en sursaut, elle court sans s'arrêter et sa roue entraîne les engrenages
## qu'elle touche, comme un moteur. Miroir : sens de sa course.

const WHEEL_RADIUS := 44.0
const RUN_SPEED := 2.0

var awake := false


func _build() -> void:
	var axle := make_static()
	axle.collision_layer = Part.LAYER_GEARS
	axle.collision_mask = 0
	add_box(axle, Vector2(16, 56), Vector2(0, 38))
	add_visual(axle, _paint_stand)
	wheel = make_rigid(1.0, 0.1, 0.8, 0.0)
	wheel.collision_layer = Part.LAYER_GEARS
	wheel.collision_mask = Part.LAYER_WORLD
	wheel.angular_damp = 0.0
	add_disc(wheel, WHEEL_RADIUS - TOOTH)
	add_visual(wheel, _paint_wheel)
	# La souris reste à plat au fond de la roue, quelle que soit la rotation de celle-ci.
	add_visual(axle, _paint_mouse).z_index = 1
	if running:
		var joint := PinJoint2D.new()
		add_child(joint)
		joint.node_a = joint.get_path_to(axle)
		joint.node_b = joint.get_path_to(wheel)
		wheel.body_entered.connect(func(_body: Node) -> void: _wake())


func gear_radius() -> float:
	return WHEEL_RADIUS


func is_motor() -> bool:
	return false


func drive_speed() -> float:
	return RUN_SPEED * dir if awake else NAN


func rotate_step() -> float:
	return 0.0


func can_flip() -> bool:
	return true


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.5


func on_powered() -> void:
	if powered:
		_wake()


func _wake() -> void:
	if awake or not running:
		return
	awake = true
	board.sfx.play("squeak")
	refresh()


func describe() -> PackedStringArray:
	var lines := PackedStringArray([Catalog.label(kind)])
	if uses_channel():
		lines.append(Lang.t("Canal %d") % channel)
	lines.append(Lang.t("Court et fait tourner les engrenages voisins.") if awake
			else Lang.t("Dort : un choc ou son canal la réveillent."))
	var count := board.gear_neighbors(self).size() if board != null else 0
	lines.append(Lang.t("Engrène avec %d roue(s).") % count if count > 0 else Lang.t("N'engrène avec aucune roue."))
	return lines


func paint_icon(c: CanvasItem) -> void:
	_paint_stand(c)
	_paint_wheel(c)
	_paint_mouse(c)


func _paint_stand(c: CanvasItem) -> void:
	box(c, Rect2(-8, 10, 16, 56), STEEL)
	box(c, Rect2(-24, 58, 48, 8), STEEL)
	paint_channel(c, Vector2(0, 52))


func _paint_wheel(c: CanvasItem) -> void:
	var r := WHEEL_RADIUS
	var teeth := 30
	var outline := PackedVector2Array()
	for i in teeth * 2:
		outline.append(Vector2.from_angle(TAU * i / (teeth * 2)) * (r if i % 2 == 0 else r - TOOTH))
	poly(c, outline, Color("9fb4c8"))
	c.draw_circle(Vector2.ZERO, r - TOOTH - 4.0, Color("2a3a57"))
	for i in 8:
		var a := TAU * i / 8.0
		c.draw_line(Vector2.ZERO, Vector2.from_angle(a) * (r - TOOTH - 4.0), Color("9fb4c8"), 2.0)
	c.draw_circle(Vector2.ZERO, 5.0, INK)


func _paint_mouse(c: CanvasItem) -> void:
	var floor_y := WHEEL_RADIUS - TOOTH - 10.0
	var body := Vector2(0, floor_y - 9.0)
	var fur := Color("c8c2bb")
	var face := float(dir)
	c.draw_circle(body, 10.0, fur)
	c.draw_circle(body + Vector2(11.0 * face, -3.0), 7.0, fur)
	c.draw_circle(body + Vector2(8.0 * face, -11.0), 4.0, Color("e8a0a8"))
	c.draw_circle(body + Vector2(18.0 * face, -3.0), 2.0, Color("e0566b"))
	var tail := PackedVector2Array()
	for i in 6:
		tail.append(body + Vector2(-face * (10.0 + i * 3.0), sin(i * 1.2 + anim * 12.0) * 2.0))
	c.draw_polyline(tail, Color("e8a0a8"), 1.5)
	if awake:
		c.draw_circle(body + Vector2(13.0 * face, -5.0), 1.5, INK)
		for leg in 2:
			var swing := sin(anim * 24.0 + leg * PI) * 6.0
			c.draw_line(body + Vector2((leg * 8.0 - 4.0), 7.0), body + Vector2(leg * 8.0 - 4.0 + swing, 10.0), INK, 2.0)
	else:
		c.draw_line(body + Vector2(11.0 * face, -5.0), body + Vector2(15.0 * face, -5.0), INK, 1.5)
		c.draw_string(ThemeDB.fallback_font, body + Vector2(-6.0, -16.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))
