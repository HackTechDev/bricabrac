class_name WaterPart
extends Part
## Bac d'eau. La poussée d'Archimède s'applique à la partie immergée de chaque objet : ce qui est
## moins dense que l'eau flotte (caisse, domino, balle rebond), le reste coule lentement (bille,
## boulet). L'eau freine aussi tout ce qui la traverse.

const INNER := Vector2(220, 120)
const WALL := 10.0
## Hauteur d'eau, depuis le fond intérieur.
const DEPTH := 96.0
## Densité de l'eau, en masse par pixel carré : la bille d'acier (0,0019) coule, la caisse
## (0,0010) flotte.
const DENSITY := 0.0015
const DRAG := 3.0
const ANGULAR_DRAG := 2.0
const CIRCLE_SIDES := 16

var area: Area2D


func _build() -> void:
	var tank := make_static(0.0, 0.8)
	for side: float in [-1.0, 1.0]:
		add_box(tank, Vector2(WALL, INNER.y + WALL), Vector2(side * (INNER.x + WALL) / 2.0, WALL / 2.0))
	add_box(tank, Vector2(INNER.x, WALL), Vector2(0, (INNER.y + WALL) / 2.0))
	# L'eau se dessine par-dessus les objets immergés.
	var water := add_visual(tank, _paint_water)
	water.z_index = 1
	add_visual(tank, paint)
	area = add_sensor(Vector2(INNER.x, DEPTH), Vector2(0, _surface_y() + DEPTH / 2.0), _splash)
	if area != null:
		area.body_exited.connect(_splash)


func icon_scale() -> float:
	return 0.2


func rotate_step() -> float:
	return 0.0


func can_tie() -> bool:
	return false


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Fait flotter la caisse, le domino et la balle rebond ; la bille et le boulet coulent."))
	return lines


## Vitesse en dessous de laquelle un objet entre ou sort de l'eau sans éclabousser.
const SPLASH_SPEED := 90.0
const SPLASH_FULL := 600.0


## Gouttes à la surface quand un objet y plonge ou en ressort assez vite.
func _splash(node: Node) -> void:
	var body := node as RigidBody2D
	if body == null or body.linear_velocity.length() < SPLASH_SPEED:
		return
	var local := to_local(body.global_position)
	var x := clampf(local.x, -INNER.x / 2.0, INNER.x / 2.0)
	board.effects.splash(board.to_local(to_global(Vector2(x, _surface_y()))),
			body.linear_velocity.length() / SPLASH_FULL)


## Ordonnée locale de la surface de l'eau.
func _surface_y() -> float:
	return INNER.y / 2.0 - DEPTH


func _physics_process(delta: float) -> void:
	super(delta)
	if area == null:
		return
	var inv := global_transform.affine_inverse()
	var water := PackedVector2Array([
		Vector2(-INNER.x / 2.0, _surface_y()), Vector2(INNER.x / 2.0, _surface_y()),
		Vector2(INNER.x / 2.0, _surface_y() + DEPTH), Vector2(-INNER.x / 2.0, _surface_y() + DEPTH)])
	for node in area.get_overlapping_bodies():
		var body := node as RigidBody2D
		if body == null or body.freeze:
			continue
		var gravity := body.get_gravity()
		for child in body.get_children():
			var col := child as CollisionShape2D
			if col == null:
				continue
			var outline := _outline(col.shape)
			if outline.is_empty():
				continue
			var local := inv * col.global_transform * outline
			for piece in Geometry2D.intersect_polygons(local, water):
				var sub := _area_centroid(piece)
				if sub.x <= 0.0:
					continue
				var at := global_transform * Vector2(sub.y, sub.z)
				var lift := -gravity * DENSITY * sub.x
				var drag := -body.linear_velocity * DRAG * body.mass * minf(sub.x / _shape_area(outline), 1.0)
				body.apply_force(lift + drag, at - body.global_position)
		body.apply_torque(-body.angular_velocity * ANGULAR_DRAG * body.inertia)


static func _outline(shape: Shape2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		for i in CIRCLE_SIDES:
			points.append(Vector2.from_angle(TAU * i / CIRCLE_SIDES) * r)
	elif shape is RectangleShape2D:
		var e := (shape as RectangleShape2D).size / 2.0
		points = PackedVector2Array([Vector2(-e.x, -e.y), Vector2(e.x, -e.y), e, Vector2(-e.x, e.y)])
	elif shape is ConvexPolygonShape2D:
		points = (shape as ConvexPolygonShape2D).points
	return points


static func _shape_area(points: PackedVector2Array) -> float:
	return absf(_area_centroid(points).x)


## Aire puis centre de gravité d'un polygone, sous la forme (aire, x, y).
static func _area_centroid(points: PackedVector2Array) -> Vector3:
	var area_sum := 0.0
	var c := Vector2.ZERO
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var cross := a.cross(b)
		area_sum += cross
		c += (a + b) * cross
	if absf(area_sum) < 0.001:
		return Vector3.ZERO
	c /= 3.0 * area_sum
	return Vector3(absf(area_sum) / 2.0, c.x, c.y)


func _paint_water(c: CanvasItem) -> void:
	var top := _surface_y()
	var rect := Rect2(-INNER.x / 2.0, top, INNER.x, DEPTH)
	c.draw_rect(rect, Color(0.25, 0.6, 1.0, 0.45))
	var wave := PackedVector2Array()
	for i in 23:
		var x := -INNER.x / 2.0 + INNER.x * i / 22.0
		wave.append(Vector2(x, top + sin(i * 1.3) * 1.5))
	c.draw_polyline(wave, Color(0.75, 0.9, 1.0, 0.9), 2.0)


func paint(c: CanvasItem) -> void:
	var glass := Color(0.75, 0.85, 0.95, 0.9)
	box(c, Rect2(-INNER.x / 2.0 - WALL, INNER.y / 2.0, INNER.x + 2.0 * WALL, WALL), glass)
	for side: float in [-1.0, 1.0]:
		var x := side * (INNER.x + WALL) / 2.0
		box(c, Rect2(x - WALL / 2.0, -INNER.y / 2.0, WALL, INNER.y + WALL), glass)


func paint_icon(c: CanvasItem) -> void:
	_paint_water(c)
	paint(c)
