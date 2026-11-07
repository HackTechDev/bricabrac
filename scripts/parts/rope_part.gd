class_name RopePart
extends Part
## Corde : relie deux pièces, en passant éventuellement par des poulies.
## Sa longueur totale ne peut pas augmenter : elle tire, mais ne pousse jamais.
## Elle ne heurte rien. Godot n'ayant pas de joint poulie en 2D, la contrainte est résolue ici.

const COLOR := Color("e8d9b5")
const STIFFNESS := 0.2
const MAX_CORRECTION := 500.0
const TWANG_SPEED := 180.0

var rest_length := 0.0
## Plus grand allongement observé : les tests s'en servent pour vérifier la contrainte.
var max_stretch := 0.0

var _a: Part
var _b: Part
var _via: Array[PulleyPart] = []
var _first_span := 0.0
var _cut := false


class End:
	var state: PhysicsDirectBodyState2D
	var point: Vector2
	var dir: Vector2
	var arm: Vector2

	func _init(body: PhysicsBody2D, p_point: Vector2, p_dir: Vector2) -> void:
		point = p_point
		dir = p_dir
		if body is RigidBody2D:
			state = PhysicsServer2D.body_get_direct_state(body.get_rid())
			if state != null:
				arm = point - (state.transform.origin + state.center_of_mass)

	## Vitesse à laquelle ce bout s'éloigne de la corde : il l'allonge.
	func pull_rate() -> float:
		if state == null:
			return 0.0
		var spin_speed := Vector2(-arm.y, arm.x) * state.angular_velocity
		return -(state.linear_velocity + spin_speed).dot(dir)

	func softness() -> float:
		if state == null:
			return 0.0
		var lever := arm.cross(dir)
		return state.inverse_mass + state.inverse_inertia * lever * lever

	func apply(impulse: float) -> void:
		if state == null:
			return
		state.linear_velocity += dir * impulse * state.inverse_mass
		state.angular_velocity += arm.cross(dir) * impulse * state.inverse_inertia


func _build() -> void:
	add_visual(self, paint)
	if running and _resolve():
		var path := points()
		rest_length = _measure(path)
		_first_span = path[0].distance_to(path[1])


func is_animated() -> bool:
	return true


func can_tie() -> bool:
	return false


func icon_scale() -> float:
	return 1.0


## Fin de corde liée à une pièce donnée, ou passant par elle ?
func depends_on(id: String) -> bool:
	return entry.get("from", "") == id or entry.get("to", "") == id or entry.get("via", []).has(id)


func hit_test(point: Vector2) -> bool:
	var path := points()
	for i in range(1, path.size()):
		var nearest := Geometry2D.get_closest_point_to_segment(point, path[i - 1], path[i])
		if nearest.distance_to(point) <= 7.0:
			return true
	return false


## Tracé en coordonnées du plateau ; vide si une pièce manque.
func points() -> PackedVector2Array:
	if not _resolve() or _cut:
		return PackedVector2Array()
	var path := PackedVector2Array()
	path.append(board.to_local(_a.main_body.to_global(entry.get("from_off", Vector2.ZERO))))
	for pulley in _via:
		path.append(board.to_local(pulley.global_position))
	path.append(board.to_local(_b.main_body.to_global(entry.get("to_off", Vector2.ZERO))))
	return path


func _physics_process(_delta: float) -> void:
	if _cut or _a == null:
		return
	if not _attached(_a) or not _attached(_b):
		_cut = true
		refresh()
		return
	var path := points()
	var length := _measure(path)
	var stretch := length - rest_length
	max_stretch = maxf(max_stretch, stretch)
	_turn_pulleys(path)
	var last := path.size() - 1
	var a := End.new(_a.main_body, board.to_global(path[0]),
			(path[1] - path[0]).normalized())
	var b := End.new(_b.main_body, board.to_global(path[last]),
			(path[last - 1] - path[last]).normalized())
	var softness := a.softness() + b.softness()
	if softness <= 0.0:
		return
	# Vitesse d'allongement autorisée : la corde peut se tendre, puis se rattrape si elle a trop cédé.
	var dt := 1.0 / Engine.physics_ticks_per_second
	var allowed := -stretch / dt
	if stretch > 0.0:
		allowed = -minf(STIFFNESS * stretch / dt, MAX_CORRECTION)
	var excess := a.pull_rate() + b.pull_rate() - allowed
	if excess <= 0.0:
		return
	var impulse := excess / softness
	a.apply(impulse)
	b.apply(impulse)
	if excess > TWANG_SPEED and stretch > -1.0:
		board.sfx.play("twang", excess / 900.0)


func _turn_pulleys(path: PackedVector2Array) -> void:
	if _via.is_empty():
		return
	var span := path[0].distance_to(path[1])
	var moved := span - _first_span
	_first_span = span
	for pulley in _via:
		pulley.spin += moved / PulleyPart.RADIUS
		pulley.refresh()


func _resolve() -> bool:
	if running and _a != null:
		return true
	_via.clear()
	_a = board.find_part(entry.get("from", ""))
	_b = board.find_part(entry.get("to", ""))
	for id: String in entry.get("via", []):
		var pulley := board.find_part(id) as PulleyPart
		if pulley == null:
			_a = null
			return false
		_via.append(pulley)
	if _a == null or _b == null:
		_a = null
		return false
	return true


func _attached(part: Part) -> bool:
	var body := part.main_body
	return is_instance_valid(body) and not body.is_queued_for_deletion()


func _measure(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


func paint(c: CanvasItem) -> void:
	var path := points()
	if path.size() < 2:
		return
	var col := Color.WHITE if selected else COLOR
	var slack := rest_length - _measure(path) if running else 0.0
	var sag := minf(sqrt(maxf(slack, 0.0)) * 4.0, 90.0) if slack > 2.0 else 0.0
	for i in range(1, path.size()):
		if sag > 0.0:
			var curve := PackedVector2Array()
			for s in 13:
				var t := s / 12.0
				curve.append(path[i - 1].lerp(path[i], t) + Vector2.DOWN * sag * 4.0 * t * (1.0 - t))
			c.draw_polyline(curve, col, 2.5)
		else:
			c.draw_line(path[i - 1], path[i], col, 2.5)
	c.draw_circle(path[0], 4.0, col)
	c.draw_circle(path[path.size() - 1], 4.0, col)


func paint_icon(c: CanvasItem) -> void:
	for r: float in [15.0, 10.0, 5.0]:
		c.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, COLOR, 2.5)
