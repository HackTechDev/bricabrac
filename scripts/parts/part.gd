class_name Part
extends Node2D
## Base de toutes les pièces. Une pièce est décrite par une entrée de disposition
## (Dictionary : kind, pos, rot, dir, channel, len, goal, accepts…) et reconstruite
## à partir d'elle : on repart donc toujours d'un état initial identique.

const INK := Color("0f1a2e")
const STEEL := Color("7f8fa6")
const WOOD := Color("c98f4e")
const GOLD := Color("ffc94d")
## Couches physiques : les roues dentées ne se heurtent pas entre elles, mais heurtent le reste.
const LAYER_WORLD := 1
const LAYER_GEARS := 2
const IMPACT_MIN_SPEED := 70.0
const IMPACT_FULL_SPEED := 700.0
## Choc à partir duquel un nuage de poussière se lève.
const IMPACT_DUST_SPEED := 160.0
## Écrasement au plus fort d'un choc (part de la taille), et durée du retour à la forme.
const SQUASH_MAX := 0.3
const SQUASH_TIME := 0.3
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
## Écrasement visuel après un choc : amplitude, temps écoulé, direction du choc (monde).
var _squash := 0.0
var _squash_time := 0.0
var _squash_normal := Vector2.UP


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
	if entry.get("goal", false) and main_body != null:
		add_visual(main_body, _paint_goal_mark).z_index = 2
	set_physics_process(running)
	set_process(running and is_animated())


## Étoile dorée au-dessus des pièces qui forment l'objectif du niveau.
func _paint_goal_mark(c: CanvasItem) -> void:
	var star := PackedVector2Array()
	for i in 10:
		var r := 9.0 if i % 2 == 0 else 4.0
		star.append(Vector2(0, -54) + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * r)
	poly(c, star, GOLD)


func _process(delta: float) -> void:
	anim += delta
	if _squash > 0.0:
		_update_squash(delta)
	if is_animated():
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


## Réglage numérique que R et la molette modifient à la place de la rotation, s'il existe :
## {"key", "step", "min", "max", "default", "label"}. Vide pour une pièce qui pivote.
func setting() -> Dictionary:
	return {}


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


## Rayon primitif d'une roue dentée ; 0 si la pièce n'en est pas une.
func gear_radius() -> float:
	return 0.0


func collision_layer() -> int:
	return LAYER_WORLD


func collision_mask() -> int:
	return LAYER_WORLD | LAYER_GEARS


## Deux pièces peuvent-elles se toucher ? Sinon, elles peuvent aussi se chevaucher à la pose.
func interacts_with(other: Part) -> bool:
	return (collision_layer() & other.collision_mask()) != 0 \
			or (other.collision_layer() & collision_mask()) != 0


## Attiré par les aimants ?
func is_metal() -> bool:
	return false


## Peut-on y attacher une corde ?
func can_tie() -> bool:
	return true


## Point d'attache d'une corde, dans le repère du corps, pour un clic à `point`.
func rope_anchor(_point: Vector2) -> Vector2:
	return Vector2.ZERO


## Réglages propres à cette pièce, affichés dans son infobulle (une ligne par réglage).
func describe() -> PackedStringArray:
	var lines := PackedStringArray()
	if uses_channel():
		lines.append("Canal %d" % channel if channel > 0 else "Canal 0 : toujours en marche")
	return lines


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
	b.collision_mask = LAYER_WORLD | LAYER_GEARS
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
	area.collision_mask = LAYER_WORLD | LAYER_GEARS
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
	if shock > IMPACT_DUST_SPEED:
		_dust(shock)
	if shock > IMPACT_MIN_SPEED and Effects.enabled:
		_squash = clampf(shock / IMPACT_FULL_SPEED, 0.0, 1.0) * SQUASH_MAX
		_squash_time = 0.0
		_squash_normal = (_tracked.linear_velocity - _velocity_before).normalized()
		set_process(true)


## Le dessin s'aplatit dans la direction du choc et s'élargit en travers, puis rebondit et se
## remet en forme. Seuls les nœuds de dessin changent : la forme physique reste la même.
func _update_squash(delta: float) -> void:
	_squash_time += delta
	var t := _squash_time / SQUASH_TIME
	var squash := Transform2D.IDENTITY
	if t >= 1.0:
		_squash = 0.0
		if not is_animated():
			set_process(false)
	elif is_instance_valid(_tracked):
		var a := _squash * pow(1.0 - t, 2.0) * cos(_squash_time * 30.0)
		var n := _squash_normal.rotated(-_tracked.global_rotation)
		var side := n.orthogonal()
		var stretch := func(v: Vector2) -> Vector2:
			return n * (1.0 - a) * v.dot(n) + side * (1.0 + a * 0.6) * v.dot(side)
		squash = Transform2D(stretch.call(Vector2.RIGHT), stretch.call(Vector2.DOWN), Vector2.ZERO)
	for v in visuals:
		if is_instance_valid(v) and v.get_parent() == _tracked:
			v.transform = squash


func squash_amount() -> float:
	return _squash


## Poussière au point de choc, estimé à partir du changement de vitesse : il repousse le corps
## hors de la surface touchée.
func _dust(shock: float) -> void:
	var normal := (_tracked.linear_velocity - _velocity_before).normalized()
	var reach := INF
	for s in solids:
		if s.get_parent() == _tracked:
			var r := s.shape.get_rect()
			reach = minf(reach, minf(r.size.x, r.size.y) / 2.0)
	if reach == INF:
		return
	var at := _tracked.global_position - normal * reach
	board.effects.dust(board.to_local(at), normal.rotated(-board.global_rotation), shock / IMPACT_FULL_SPEED)


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
