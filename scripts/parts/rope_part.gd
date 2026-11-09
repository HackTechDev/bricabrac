class_name RopePart
extends Part
## Corde : relie deux pièces, en passant éventuellement par des poulies.
## Sa longueur totale est celle de la pose plus un mou réglable (R, molette) : elle ne peut pas
## dépasser cette longueur, elle tire mais ne pousse jamais.
## Elle s'enroule sur ses poulies, du côté où elle tourne, et se prend aux coins des obstacles
## qu'elle rencontre en mouvement : elle les contourne, et tire sur ceux qui peuvent bouger.
## Ce qu'elle traverse déjà au lancement ne la gêne pas : la pose reste celle du joueur.
## Godot n'ayant pas de joint poulie en 2D, la contrainte est résolue ici.

const COLOR := Color("e8d9b5")
const STIFFNESS := 0.2
const MAX_CORRECTION := 500.0
const TWANG_SPEED := 180.0
## Écart entre la corde et le coin qu'elle contourne, et nombre de coins au plus.
const MARGIN := 3.0
const MAX_WRAPS := 12
## Distance au-delà de laquelle un coin, passé de l'autre côté, libère la corde.
const UNWRAP := 0.25
## Premiers pas de simulation où la longueur se recale sur les coins trouvés au départ.
const SETTLE_TICKS := 3
## Rayon des poignées des deux bouts, montrées quand la corde est choisie : on les glisse pour
## raccrocher la corde ailleurs.
const END_GRAB := 11.0

var rest_length := 0.0
## Plus grand allongement observé : les tests s'en servent pour vérifier la contrainte.
var max_stretch := 0.0

var _a: Part
var _b: Part
var _via: Array[PulleyPart] = []
var _cut := false
## Côté d'enroulement de chaque poulie (+1 ou -1), fixé au lancement.
var _sides: Array[float] = []
## Coins d'obstacles, rangés par tronçon entre deux points fixes (bouts et poulies).
var _wraps: Array = []
var _exclude: Array[RID] = []
var _settle := 0
## Dernier tracé calculé : nœuds, segments droits, longueur et longueur avant la 1re poulie.
var _nodes: Array[Dictionary] = []
var _outs: Array = []
var _length := 0.0
var _lead := 0.0
var _last_lead := 0.0


## Coin d'obstacle où la corde s'appuie, en coordonnées du corps qui le porte.
class Wrap:
	var body: CollisionObject2D
	var local: Vector2
	var side: float

	func _init(p_body: CollisionObject2D, p_local: Vector2, p_side: float) -> void:
		body = p_body
		local = p_local
		side = p_side

	func alive() -> bool:
		return is_instance_valid(body) and body.is_inside_tree() and not body.is_queued_for_deletion()

	func at() -> Vector2:
		return body.global_transform * local


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
		return state.inverse_mass * dir.length_squared() + state.inverse_inertia * lever * lever

	func apply(impulse: float) -> void:
		if state == null:
			return
		state.linear_velocity += dir * impulse * state.inverse_mass
		state.angular_velocity += arm.cross(dir) * impulse * state.inverse_inertia


func _build() -> void:
	add_visual(self, paint)
	_wraps.clear()
	_sides.clear()
	_exclude.clear()
	if running and _resolve():
		_route()
		rest_length = _rest_for(_length)
		_last_lead = _lead
		_settle = SETTLE_TICKS


## Longueur au repos pour une longueur posée donnée.
func _rest_for(length: float) -> float:
	return length + slack()


func slack() -> float:
	return entry.get("slack", 0.0)


func setting() -> Dictionary:
	return {"key": "slack", "step": 20.0, "min": 0.0, "max": 400.0, "default": 0.0, "label": Lang.t("Mou (R)")}


func is_animated() -> bool:
	return true


func can_tie() -> bool:
	return false


func icon_scale() -> float:
	return 1.0


## Coupée par des ciseaux : elle cesse de tirer et disparaît.
func cut() -> void:
	_cut = true
	refresh()


func is_cut() -> bool:
	return _cut


## Fin de corde liée à une pièce donnée, ou passant par elle ?
func depends_on(id: String) -> bool:
	return entry.get("from", "") == id or entry.get("to", "") == id or entry.get("via", []).has(id)


## Bout de la corde sous `point` ("from" ou "to"), ou "" ; en coordonnées du plateau.
func end_at(point: Vector2) -> String:
	if not _resolve() or _cut:
		return ""
	for end: String in ["from", "to"]:
		if end_position(end).distance_to(point) <= END_GRAB:
			return end
	return ""


## Point d'attache d'un bout ("from" ou "to"), en coordonnées du plateau.
func end_position(end: String) -> Vector2:
	if not _resolve():
		return Vector2.INF
	return board.to_local(_anchor_a() if end == "from" else _anchor_b())


func hit_test(point: Vector2) -> bool:
	var path := points()
	for i in range(1, path.size()):
		var nearest := Geometry2D.get_closest_point_to_segment(point, path[i - 1], path[i])
		if nearest.distance_to(point) <= 7.0:
			return true
	return false


## Tracé en coordonnées du plateau, arcs de poulies compris ; vide si une pièce manque.
func points() -> PackedVector2Array:
	if not _resolve() or _cut:
		return PackedVector2Array()
	var path := PackedVector2Array()
	for point in _route():
		path.append(board.to_local(point))
	return path


func _physics_process(_delta: float) -> void:
	if not _advance():
		return
	var stretch := _length - rest_length
	max_stretch = maxf(max_stretch, stretch)
	var ends := _ends()
	var softness := 0.0
	var rate := 0.0
	for end in ends:
		softness += end.softness()
		rate += end.pull_rate()
	if softness <= 0.0:
		return
	# Vitesse d'allongement autorisée : la corde peut se tendre, puis se rattrape si elle a trop cédé.
	var dt := get_physics_process_delta_time()  # Fixe, même en accéléré.
	var allowed := -stretch / dt
	if stretch > 0.0:
		allowed = -minf(STIFFNESS * stretch / dt, MAX_CORRECTION)
	var excess := rate - allowed
	if excess <= 0.0:
		return
	var impulse := excess / softness
	for end in ends:
		end.apply(impulse)
	if excess > TWANG_SPEED and stretch > -1.0:
		board.sfx.play("twang", excess / 900.0)


## Un pas de simulation : coins pris ou lâchés, tracé, poulies. Faux si la corde ne tire plus.
func _advance() -> bool:
	if _cut or _a == null:
		return false
	if not _attached(_a) or not _attached(_b):
		_cut = true
		refresh()
		return false
	if _settle > 0:
		_ignore_crossed()
	else:
		_update_wraps()
	_route()
	if _settle > 0:
		_settle -= 1
		rest_length = _rest_for(_length)
		_last_lead = _lead
	_turn_pulleys()
	return true


## Points où la corde agit : ses deux bouts, et les coins portés par des corps mobiles.
func _ends() -> Array[End]:
	var ends: Array[End] = []
	var first: Vector2 = _outs[0][0]
	var last: Vector2 = _outs[_outs.size() - 1][1]
	ends.append(End.new(_a.main_body, first, (_outs[0][1] - first).normalized()))
	ends.append(End.new(_b.main_body, last, (_outs[_outs.size() - 1][0] - last).normalized()))
	for i in range(1, _nodes.size() - 1):
		var hook: Wrap = _nodes[i].get("wrap")
		if hook != null and hook.body is RigidBody2D:
			var w: Vector2 = _nodes[i].pos
			var pull: Vector2 = (_outs[i - 1][0] - w).normalized() + (_outs[i][1] - w).normalized()
			ends.append(End.new(hook.body as RigidBody2D, w, pull))
	return ends


func _turn_pulleys() -> void:
	var moved := _lead - _last_lead
	_last_lead = _lead
	for i in _via.size():
		_via[i].spin -= moved / PulleyPart.RADIUS * _side(i)
		_via[i].refresh()


## Côté d'enroulement : la poulie reste à l'intérieur du virage que prend la corde.
func _side(i: int) -> float:
	if i < _sides.size():
		return _sides[i]
	var prev: Vector2 = _anchor_a() if i == 0 else _via[i - 1].global_position
	var next: Vector2 = _anchor_b() if i == _via.size() - 1 else _via[i + 1].global_position
	var here := _via[i].global_position
	return -1.0 if (here - prev).cross(next - here) > 0.0 else 1.0


func _anchor_a() -> Vector2:
	return _a.main_body.to_global(entry.get("from_off", Vector2.ZERO))


func _anchor_b() -> Vector2:
	return _b.main_body.to_global(entry.get("to_off", Vector2.ZERO))


## Points de passage dans l'ordre : bout, coins, poulie (rayon signé), coins, ..., bout.
## « span » et « k » disent où insérer un coin qui suivrait ce nœud.
func _list_nodes() -> Array[Dictionary]:
	if running and _sides.size() != _via.size():
		_sides.clear()
		for i in _via.size():
			_sides.append(_side(i))
	var list: Array[Dictionary] = [{"pos": _anchor_a(), "rho": 0.0, "span": 0, "k": -1}]
	for span in _via.size() + 1:
		var wraps: Array = _wraps[span] if span < _wraps.size() else []
		for k in wraps.size():
			var hook: Wrap = wraps[k]
			if hook.alive():
				list.append({"pos": hook.at(), "rho": 0.0, "span": span, "k": k, "wrap": hook})
		if span < _via.size():
			list.append({"pos": _via[span].global_position, "rho": _side(span) * PulleyPart.RADIUS,
					"span": span + 1, "k": -1})
	list.append({"pos": _anchor_b(), "rho": 0.0, "span": _via.size(), "k": 1 << 20})
	return list


## Segment tangent à deux cercles de rayons signés (rayon nul : un simple point).
static func _tangent(c1: Vector2, r1: float, c2: Vector2, r2: float) -> Array[Vector2]:
	var d := c2 - c1
	var dist := d.length()
	if dist < 0.001:
		return [c1, c2]
	var u := d / dist
	var k := clampf((r1 - r2) / dist, -1.0, 1.0)
	var n := u * k + Vector2(-u.y, u.x) * sqrt(1.0 - k * k)
	return [c1 + n * r1, c2 + n * r2]


## Calcule le tracé (coordonnées globales) et sa longueur exacte, arcs compris.
func _route() -> PackedVector2Array:
	_nodes = _list_nodes()
	_outs.clear()
	for i in _nodes.size() - 1:
		_outs.append(_tangent(_nodes[i].pos, _nodes[i].rho, _nodes[i + 1].pos, _nodes[i + 1].rho))
	var path := PackedVector2Array([_outs[0][0]])
	_length = 0.0
	_lead = -1.0
	for i in range(1, _nodes.size()):
		var enter: Vector2 = _outs[i - 1][1]
		_length += path[path.size() - 1].distance_to(enter)
		path.append(enter)
		var rho: float = _nodes[i].rho
		if i == _nodes.size() - 1 or rho == 0.0:
			continue
		if _lead < 0.0:
			_lead = _length
		var center: Vector2 = _nodes[i].pos
		var exit: Vector2 = _outs[i][0]
		var a_in := (enter - center).angle()
		var a_out := (exit - center).angle()
		# Rayon positif : la corde tourne dans le sens des angles décroissants.
		var sweep := wrapf(a_in - a_out, 0.0, TAU) if rho > 0.0 else -wrapf(a_out - a_in, 0.0, TAU)
		var steps := maxi(2, ceili(absf(sweep) / 0.2))
		for step in range(1, steps + 1):
			path.append(center + Vector2.from_angle(a_in - sweep * step / steps) * absf(rho))
		_length += absf(sweep * rho)
	if _lead < 0.0:
		_lead = _length
	return path


## Lâche les coins dépassés, puis accroche ceux que les segments droits traversent.
func _update_wraps() -> void:
	while _wraps.size() < _via.size() + 1:
		_wraps.append([])
	for span: Array in _wraps:
		for k in range(span.size() - 1, -1, -1):
			if not (span[k] as Wrap).alive():
				span.remove_at(k)
	for attempt in MAX_WRAPS:
		_route()
		var freed := false
		for i in range(1, _nodes.size() - 1):
			var hook: Wrap = _nodes[i].get("wrap")
			if hook != null and _offset(_outs[i - 1][0], _outs[i][1], _nodes[i].pos) * hook.side < -UNWRAP:
				_wraps[_nodes[i].span].remove_at(_nodes[i].k)
				freed = true
				break
		if not freed:
			break
	for attempt in 4:
		if _wrap_count() >= MAX_WRAPS:
			return
		_route()
		var added := false
		for i in _outs.size():
			var hook := _find_wrap(_outs[i][0], _outs[i][1], _nodes[i], _nodes[i + 1])
			if hook != null:
				_wraps[_nodes[i].span].insert(_nodes[i].k + 1, hook)
				added = true
				break
		if not added:
			return


func _wrap_count() -> int:
	var count := 0
	for span: Array in _wraps:
		count += span.size()
	return count


## Distance signée d'un point à la droite p → q.
static func _offset(p: Vector2, q: Vector2, point: Vector2) -> float:
	var line := q - p
	var length := line.length()
	return 0.0 if length < 0.001 else line.cross(point - p) / length


## Le segment p → q traverse-t-il un obstacle ? Renvoie le coin à contourner : celui du côté
## le moins enfoncé, c'est-à-dire celui que la corde vient de franchir.
func _find_wrap(p: Vector2, q: Vector2, from: Dictionary, to: Dictionary) -> Wrap:
	if p.distance_to(q) < 2.0:
		return null
	var query := PhysicsRayQueryParameters2D.create(p, q, LAYER_WORLD, _excluded())
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var body := hit.get("collider") as CollisionObject2D
	if body == null:
		return null
	var corners := _corners(body, hit.shape)
	var line := q - p
	var best: Array[int] = [-1, -1]
	var depth: Array[float] = [0.0, 0.0]
	for j in corners.size():
		var v := body.global_transform * corners[j]
		var t := (v - p).dot(line) / line.length_squared()
		if t <= 0.0 or t >= 1.0:
			continue
		var d := _offset(p, q, v)
		var s := 0 if d > 0.0 else 1
		if absf(d) > depth[s]:
			depth[s] = absf(d)
			best[s] = j
	var side := 0 if best[1] < 0 or (best[0] >= 0 and depth[0] <= depth[1]) else 1
	if best[side] < 0:
		return null
	var local := corners[best[side]]
	for node in [from, to]:
		var other: Wrap = node.get("wrap")
		if other != null and other.body == body and other.local.distance_to(local) < 1.0:
			return null
	return Wrap.new(body, local, 1.0 if side == 0 else -1.0)


## Coins d'une forme, écartés de MARGIN, en coordonnées du corps. Un disque devient un polygone.
static func _corners(body: CollisionObject2D, shape_index: int) -> PackedVector2Array:
	var corners := PackedVector2Array()
	var shape_owner := body.shape_find_owner(shape_index)
	var shape := body.shape_owner_get_shape(shape_owner, 0)
	var xf := body.shape_owner_get_transform(shape_owner)
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size / 2.0
		for quadrant: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners.append(xf * ((half + Vector2.ONE * MARGIN) * quadrant))
	elif shape is CircleShape2D:
		var r := ((shape as CircleShape2D).radius + MARGIN) / cos(PI / 12.0)
		for i in 12:
			corners.append(xf * (Vector2.from_angle(i * TAU / 12.0) * r))
	elif shape is ConvexPolygonShape2D:
		var hull := (shape as ConvexPolygonShape2D).points
		var center := Vector2.ZERO
		for point in hull:
			center += point / hull.size()
		for point in hull:
			corners.append(xf * (point + (point - center).normalized() * MARGIN * 1.5))
	return corners


## Au lancement, les obstacles que la corde traverse déjà la laissent passer.
func _ignore_crossed() -> void:
	_route()
	var space := get_world_2d().direct_space_state
	for out: Array in _outs:
		for attempt in 8:
			var query := PhysicsRayQueryParameters2D.create(out[0], out[1], LAYER_WORLD, _excluded())
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			_exclude.append(hit.rid)


## Les pièces liées par la corde ne l'arrêtent pas : elle part d'elles ou s'y enroule déjà.
func _excluded() -> Array[RID]:
	if _exclude.is_empty():
		var parts: Array[Part] = [_a, _b]
		parts.append_array(_via)
		for part in parts:
			for node in part.find_children("*", "CollisionObject2D", true, false):
				_exclude.append((node as CollisionObject2D).get_rid())
	return _exclude


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


func describe() -> PackedStringArray:
	var lines := PackedStringArray()
	var via: int = entry.get("via", []).size()
	if via > 0:
		lines.append(Lang.t("Passe par %d poulie(s)") % via)
	lines.append(Lang.t("Mou : %d px") % slack() if slack() > 0.0 else Lang.t("Tendue (R : ajouter du mou)"))
	return lines


func paint(c: CanvasItem) -> void:
	var path := points()
	if path.size() < 2:
		return
	var col := Color.WHITE if selected else COLOR
	var extra := rest_length - _measure(path) if running else slack()
	var sag := minf(sqrt(maxf(extra, 0.0)) * 4.0, 90.0) if extra > 2.0 else 0.0
	for i in range(1, path.size()):
		# Les petits segments d'un arc de poulie restent droits : la corde y est plaquée.
		if sag > 0.0 and path[i - 1].distance_to(path[i]) > 30.0:
			# Le mou fait ployer la corde vers le bas, ou sur le côté si elle est verticale.
			var bow := (path[i] - path[i - 1]).orthogonal().normalized()
			if bow.y < 0.0 or (is_zero_approx(bow.y) and bow.x < 0.0):
				bow = -bow
			var curve := PackedVector2Array()
			for s in 13:
				var t := s / 12.0
				curve.append(path[i - 1].lerp(path[i], t) + bow * sag * 4.0 * t * (1.0 - t))
			c.draw_polyline(curve, col, 2.5)
		else:
			c.draw_line(path[i - 1], path[i], col, 2.5)
	c.draw_circle(path[0], 4.0, col)
	c.draw_circle(path[path.size() - 1], 4.0, col)
	if selected and not running:
		# Poignées : glisser un bout le raccroche à une autre pièce.
		for at: Vector2 in [path[0], path[path.size() - 1]]:
			c.draw_circle(at, END_GRAB - 3.0, Color(col, 0.25))
			c.draw_arc(at, END_GRAB - 3.0, 0.0, TAU, 24, col, 2.0)


func paint_icon(c: CanvasItem) -> void:
	for r: float in [15.0, 10.0, 5.0]:
		c.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, COLOR, 2.5)
