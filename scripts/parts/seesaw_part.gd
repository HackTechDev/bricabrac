class_name SeesawPart
extends Part
## Bascule : démarre penchée (Miroir choisit le côté bas) ; une charge sur le côté
## haut catapulte ce qui repose sur le côté bas.

const LENGTH := 240.0
const THICKNESS := 14.0
const TILT := 18.0
const LIP := Vector2(8, 12)

var plank: RigidBody2D


func _build() -> void:
	var base := make_static()
	var points := _triangle()
	add_poly(base, points)
	add_visual(base, _paint_base)
	plank = make_rigid(1.5, 0.05, 0.9)
	add_box(plank, Vector2(LENGTH, THICKNESS))
	# Butées : une bille posée sur le côté bas ne roule pas hors de la bascule.
	for side: float in [-1.0, 1.0]:
		add_box(plank, LIP, Vector2(side * (LENGTH - LIP.x) / 2.0, -(THICKNESS + LIP.y) / 2.0))
	add_visual(plank, _paint_plank)
	plank.rotation_degrees = TILT * dir
	if running:
		# Pivot sans butée : la butée angulaire du PinJoint2D, heurtée par un objet lourd,
		# fait tourner la planche à plus de 50 tours par seconde et projette la bille à des
		# milliers de px/s. La butée est donc faite à la main (_physics_process).
		var joint := PinJoint2D.new()
		add_child(joint)
		joint.node_a = joint.get_path_to(base)
		joint.node_b = joint.get_path_to(plank)


## Butée : la planche ne dépasse pas ±TILT ; arrivée en butée, elle s'arrête net.
func _physics_process(_delta: float) -> void:
	if not running or plank == null:
		return
	var limit := deg_to_rad(TILT)
	var outward := signf(plank.rotation)
	if absf(plank.rotation) > limit and signf(plank.angular_velocity) == outward:
		plank.angular_velocity = 0.0
		plank.rotation = limit * outward


func can_flip() -> bool:
	return true


func icon_scale() -> float:
	return 0.2


func paint_icon(c: CanvasItem) -> void:
	_paint_base(c)
	_paint_plank(c)


func rope_anchor(point: Vector2) -> Vector2:
	var side := signf(main_body.to_local(point).x)
	return Vector2((LENGTH / 2.0 - 20.0) * (side if side != 0.0 else 1.0), 0)


func _triangle() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 6), Vector2(26, 44), Vector2(-26, 44)])


func _paint_base(c: CanvasItem) -> void:
	poly(c, _triangle(), STEEL)


func _paint_plank(c: CanvasItem) -> void:
	box(c, Rect2(-LENGTH / 2.0, -THICKNESS / 2.0, LENGTH, THICKNESS), WOOD)
	for side: float in [-1.0, 1.0]:
		var at := Vector2(side * (LENGTH - LIP.x) / 2.0, -(THICKNESS + LIP.y) / 2.0)
		box(c, Rect2(at - LIP / 2.0, LIP), WOOD)
	c.draw_circle(Vector2.ZERO, 4.0, INK)
