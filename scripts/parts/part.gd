class_name Part
extends Node2D
## Base de toutes les pièces. Une pièce est décrite par une entrée de disposition
## (Dictionary : kind, pos, rot, dir, channel, len, goal, accepts…) et reconstruite
## à partir d'elle : on repart donc toujours d'un état initial identique.

const INK := Color("0f1a2e")
const STEEL := Color("7f8fa6")
const WOOD := Color("c98f4e")
const GOLD := Color("ffc94d")
const IMPACT_MIN_SPEED := 70.0
const IMPACT_FULL_SPEED := 700.0
const CHANNEL_COLORS: Array[Color] = [
	Color("8a94a6"), Color("ff5d5d"), Color("ffc94d"), Color("5dd39e"),
]

var kind := ""
var entry := {}
var board: Board
var running := false
var dir := 1
var channel := 0
var powered := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()
		refresh()
var main_body: PhysicsBody2D
var solids: Array[CollisionShape2D] = []
var visuals: Array[Node2D] = []
var anim := 0.0

var _tracked: RigidBody2D
var _velocity_before := Vector2.ZERO


func setup(p_entry: Dictionary, p_board: Board, p_running: bool) -> void:
	entry = p_entry
	board = p_board
	running = p_running
	position = entry.get("pos", Vector2.ZERO)
	rotation_degrees = entry.get("rot", 0.0)
	dir = entry.get("dir", 1)
	channel = entry.get("channel", 0)
	powered = channel == 0


func _ready() -> void:
	_build()
	set_physics_process(running)
	set_process(running and is_animated())


func _process(delta: float) -> void:
	anim += delta
	refresh()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_tracked):
		_velocity_before = _tracked.linear_velocity


# --- À redéfinir dans les pièces ------------------------------------------------

func _build() -> void:
	pass


func paint(_c: CanvasItem) -> void:
	pass


func paint_icon(c: CanvasItem) -> void:
	paint(c)


func icon_scale() -> float:
	return 1.0


func rotate_step() -> float:
	return 0.0


func can_flip() -> bool:
	return false


## Canaux possibles : la plaque et le canon exigent un canal, un tapis peut s'en passer.
func channel_range() -> Vector2i:
	return Vector2i(-1, -1)


func is_animated() -> bool:
	return false


func is_satisfied() -> bool:
	return true


func on_powered() -> void:
	pass


## Son joué quand la pièce heurte quelque chose ; vide = silencieuse.
func impact_sound() -> String:
	return ""


## Peut-on y attacher une corde ?
func can_tie() -> bool:
	return true


## Point d'attache d'une corde, dans le repère du corps, pour un clic à `point`.
func rope_anchor(_point: Vector2) -> Vector2:
	return Vector2.ZERO


## `point` est en coordonnées du plateau.
func hit_test(point: Vector2) -> bool:
	return overlaps_shape(board.probe, board.global_transform * Transform2D(0.0, point))


# --- Services communs -----------------------------------------------------------

func uses_channel() -> bool:
	return channel_range().x >= 0


func set_powered(value: bool) -> void:
	if value == powered:
		return
	powered = value
	on_powered()
	refresh()


func refresh() -> void:
	for v in visuals:
		v.queue_redraw()


static func from_body(node: Node) -> Part:
	return node.get_meta("part") as Part if node.has_meta("part") else null


func make_rigid(mass: float, bounce: float, friction := 0.6, gravity := 1.0) -> RigidBody2D:
	var b := RigidBody2D.new()
	b.mass = mass
	b.gravity_scale = gravity
	b.can_sleep = false
	b.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	b.freeze = not running
	b.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	b.physics_material_override = _material(bounce, friction)
	b.set_meta("part", self)
	add_child(b)
	main_body = b
	if running:
		_tracked = b
		b.contact_monitor = true
		b.max_contacts_reported = 4
		b.body_entered.connect(_on_contact)
	return b


func make_static(bounce := 0.0, friction := 1.0) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.physics_material_override = _material(bounce, friction)
	b.set_meta("part", self)
	add_child(b)
	if main_body == null:
		main_body = b
	return b


func add_box(parent: Node2D, size: Vector2, offset := Vector2.ZERO) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	return _add_solid(parent, shape, offset)


func add_disc(parent: Node2D, radius: float) -> CollisionShape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	return _add_solid(parent, shape, Vector2.ZERO)


func add_poly(parent: Node2D, points: PackedVector2Array) -> CollisionShape2D:
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	return _add_solid(parent, shape, Vector2.ZERO)


func add_visual(parent: Node2D, painter: Callable) -> Node2D:
	var v := Node2D.new()
	parent.add_child(v)
	v.draw.connect(func() -> void: painter.call(v))
	visuals.append(v)
	return v


## Zone de détection, créée uniquement pendant la simulation.
func add_sensor(size: Vector2, offset: Vector2, on_enter := Callable()) -> Area2D:
	if not running:
		return null
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	area.position = offset
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	add_child(area)
	if on_enter.is_valid():
		area.body_entered.connect(on_enter)
	return area


func overlaps_shape(shape: Shape2D, xform: Transform2D) -> bool:
	for s in solids:
		if s.shape.collide(s.global_transform, shape, xform):
			return true
	return false


func overlaps_part(other: Part) -> bool:
	for s in other.solids:
		if overlaps_shape(s.shape, s.global_transform):
			return true
	return false


func _add_solid(parent: Node2D, shape: Shape2D, offset: Vector2) -> CollisionShape2D:
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = offset
	parent.add_child(col)
	solids.append(col)
	return col


func _on_contact(_other: Node) -> void:
	var sound := impact_sound()
	var shock := (_tracked.linear_velocity - _velocity_before).length()
	if sound != "" and shock > IMPACT_MIN_SPEED:
		board.sfx.play(sound, shock / IMPACT_FULL_SPEED)


func _material(bounce: float, friction: float) -> PhysicsMaterial:
	var m := PhysicsMaterial.new()
	m.bounce = bounce
	m.friction = friction
	return m


func _draw() -> void:
	if not selected:
		return
	for s in solids:
		draw_set_transform_matrix(global_transform.affine_inverse() * s.global_transform)
		draw_rect(s.shape.get_rect().grow(5.0), Color(1, 1, 1, 0.8), false, 2.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


# --- Dessin ---------------------------------------------------------------------

static func box(c: CanvasItem, rect: Rect2, fill: Color) -> void:
	c.draw_rect(rect, fill)
	c.draw_rect(rect, INK, false, 2.0)


static func poly(c: CanvasItem, points: PackedVector2Array, fill: Color) -> void:
	c.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	c.draw_polyline(closed, INK, 2.0)


func paint_channel(c: CanvasItem, at: Vector2) -> void:
	if not uses_channel():
		return
	var col := CHANNEL_COLORS[channel]
	c.draw_circle(at, 9.0, col)
	c.draw_arc(at, 9.0, 0.0, TAU, 20, INK, 2.0)
	if channel > 0:
		c.draw_string(ThemeDB.fallback_font, at + Vector2(-4, 5), str(channel),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
