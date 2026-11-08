class_name Board
extends Node2D
## Plateau de jeu, sans aucune interface : mode édition (tout est figé) et mode
## simulation. Chaque lancement reconstruit toutes les pièces depuis la disposition.

signal won
signal inventory_changed

const SIZE := Vector2(1040, 640)
const GRID := 10.0
const WALL := 100.0

var level := {}
var placed: Array[Dictionary] = []
var parts: Array[Part] = []
var running := false
var has_won := false
## État des canaux 1 à 3 pendant la simulation (le canal 0 est toujours en marche).
var channel_on: Array[bool] = [true, false, false, false]
var sfx := Sfx.new()
var probe := CircleShape2D.new()

var _next_id := 1
## Paires de roues qui engrènent, calculées au lancement.
var _gear_pairs: Array = []
var _part_layer: Node2D
var _wall_shapes: Array[CollisionShape2D] = []


func _ready() -> void:
	probe.radius = 3.0
	add_child(sfx)
	_build_walls()
	_part_layer = Node2D.new()
	add_child(_part_layer)


func load_level(p_level: Dictionary) -> void:
	level = p_level
	# Identifiants stables pour le décor : une corde sauvegardée doit y retrouver ses attaches.
	var fixed: Array = level.get("fixed", [])
	for i in fixed.size():
		if not fixed[i].has("id"):
			fixed[i]["id"] = "f%d" % i
	placed.clear()
	_next_id = 1
	_rebuild(false)
	inventory_changed.emit()


func start() -> void:
	_rebuild(true)


func stop() -> void:
	_rebuild(false)


func clear_placed() -> void:
	placed.clear()
	_rebuild(false)
	inventory_changed.emit()


## Copie indépendante de la disposition du joueur.
func layout() -> Array:
	var copy: Array = []
	for entry in placed:
		copy.append(entry.duplicate(true))
	return copy


## Remplace la disposition par un état déjà connu comme valide (annulation).
func set_layout(state: Array) -> void:
	placed.clear()
	for entry: Dictionary in state:
		placed.append(entry.duplicate(true))
	_bump_next_id()
	_rebuild(false)
	inventory_changed.emit()


## Remet en place une disposition sauvegardée, en écartant ce qui n'est plus valide, par exemple
## si le niveau a changé depuis. Renvoie le nombre de pièces écartées.
func restore_layout(state: Array) -> int:
	var dropped := 0
	for ropes: bool in [false, true]:
		for item: Variant in state:
			var is_rope: bool = item is Dictionary and item.get("kind") == "rope"
			if is_rope != ropes:
				continue
			if not _restore_entry(item):
				dropped += 1
	_bump_next_id()
	inventory_changed.emit()
	return dropped


func remaining(kind: String) -> int:
	var count: int = level.get("inventory", {}).get(kind, 0)
	for e in placed:
		if e.kind == kind:
			count -= 1
	return count


func place(kind: String, pos: Vector2) -> Part:
	var entry := {"kind": kind, "pos": snap(pos), "rot": 0.0, "dir": 1, "id": "p%d" % _next_id}
	_next_id += 1
	var part := _make(entry)
	if part.uses_channel():
		entry.channel = part.channel_range().x
		part.channel = entry.channel
		part.powered = part.channel == 0
	placed.append(entry)
	part.refresh()
	inventory_changed.emit()
	return part


## Pose une liste d'entrées complètes (solutions de niveau) : les cordes en dernier.
func apply_layout(layout: Array) -> Array[Part]:
	var result: Array[Part] = []
	for ropes: bool in [false, true]:
		for wanted: Dictionary in layout:
			if (wanted.kind == "rope") == ropes:
				var part := place(wanted.kind, wanted.get("pos", Vector2.ZERO))
				part.entry.merge(wanted, true)
				result.append(rebuild_part(part))
	return result


func add_rope(from: Part, from_off: Vector2, via: Array, to: Part, to_off: Vector2) -> Part:
	var part := place("rope", Vector2.ZERO)
	part.entry.merge({
		"from": from.entry.id, "from_off": from_off, "via": via, "to": to.entry.id, "to_off": to_off,
	}, true)
	return rebuild_part(part)


## Retire la pièce et les cordes qui en dépendent, qui retournent dans le bac.
func remove(part: Part) -> void:
	var id: String = part.entry.get("id", "")
	for rope in parts.duplicate():
		if rope is RopePart and rope != part and id != "" and (rope as RopePart).depends_on(id):
			placed.erase(rope.entry)
			_drop(rope)
	placed.erase(part.entry)
	_drop(part)
	inventory_changed.emit()


func find_part(id: String) -> Part:
	if id == "":
		return null
	for part in parts:
		if part.entry.get("id", "") == id:
			return part
	return null


## Recrée la pièce après un changement de sa disposition.
func rebuild_part(part: Part) -> Part:
	var entry := part.entry
	_drop(part)
	var rebuilt := _make(entry)
	_refresh_ropes()
	return rebuilt


func move_part(part: Part, pos: Vector2) -> void:
	part.entry.pos = snap(pos)
	part.position = part.entry.pos
	_refresh_ropes()


func snap(pos: Vector2) -> Vector2:
	return pos.snapped(Vector2(GRID, GRID))


func is_valid(part: Part) -> bool:
	for wall in _wall_shapes:
		if part.overlaps_shape(wall.shape, wall.global_transform):
			return false
	for other in parts:
		if other != part and part.interacts_with(other) and part.overlaps_part(other):
			return false
	return true


## Deux roues engrènent quand leurs cercles primitifs se touchent, à quelques pixels près.
const GEAR_TOLERANCE := 6.0


func gear_neighbors(part: Part) -> Array[Part]:
	var result: Array[Part] = []
	if part.gear_radius() <= 0.0:
		return result
	for other in parts:
		if other != part and other.gear_radius() > 0.0:
			var gap := part.global_position.distance_to(other.global_position)
			if absf(gap - part.gear_radius() - other.gear_radius()) <= GEAR_TOLERANCE:
				result.append(other)
	return result


func _find_gear_pairs() -> void:
	_gear_pairs.clear()
	for i in parts.size():
		for other in gear_neighbors(parts[i]):
			if parts.find(other) > i:
				_gear_pairs.append([parts[i], other])


## Les roues liées gardent des vitesses de bord égales et opposées : w1·r1 + w2·r2 = 0.
## Un moteur allumé impose sa vitesse (inertie infinie). Quelques passes suffisent pour un train.
func _solve_gears() -> void:
	if _gear_pairs.is_empty():
		return
	var states := {}
	for pair: Array in _gear_pairs:
		for gear: Part in pair:
			if not states.has(gear):
				states[gear] = PhysicsServer2D.body_get_direct_state(gear.gear_body().get_rid())
				var drive: float = gear.drive_speed()
				if not is_nan(drive):
					states[gear].angular_velocity = drive
	for iteration in 8:
		for pair: Array in _gear_pairs:
			var a: Part = pair[0]
			var b: Part = pair[1]
			var sa: PhysicsDirectBodyState2D = states[a]
			var sb: PhysicsDirectBodyState2D = states[b]
			var ia := 0.0 if not is_nan(a.drive_speed()) else sa.inverse_inertia
			var ib := 0.0 if not is_nan(b.drive_speed()) else sb.inverse_inertia
			var ra := a.gear_radius()
			var rb := b.gear_radius()
			var softness := ia * ra * ra + ib * rb * rb
			if softness <= 0.0:
				continue
			var impulse := -(sa.angular_velocity * ra + sb.angular_velocity * rb) / softness
			sa.angular_velocity += ia * ra * impulse
			sb.angular_velocity += ib * rb * impulse

func part_at(point: Vector2) -> Part:
	# Les objets passent avant les cordes qui les traversent.
	for ropes: bool in [false, true]:
		for i in range(parts.size() - 1, -1, -1):
			if (parts[i] is RopePart) == ropes and parts[i].hit_test(point):
				return parts[i]
	return null


func activate_channel(channel: int) -> void:
	set_channel(channel, true)


func toggle_channel(channel: int) -> void:
	set_channel(channel, not channel_on[channel])


func set_channel(channel: int, on: bool) -> void:
	if channel <= 0 or channel >= channel_on.size() or channel_on[channel] == on or not running:
		return
	channel_on[channel] = on
	for part in parts.duplicate():
		if part.uses_channel() and part.channel == channel:
			part.set_powered(on)


## Objet créé pendant la simulation, hors disposition.
func spawn(entry: Dictionary) -> void:
	_spawn_now.call_deferred(entry)


func _spawn_now(entry: Dictionary) -> void:
	if running:
		_make(entry)


func _physics_process(_delta: float) -> void:
	if not running:
		return
	_solve_gears()
	if has_won:
		return
	var goals := 0
	for part in parts:
		if part.entry.get("goal", false):
			goals += 1
			if not part.is_satisfied():
				return
	if goals > 0:
		has_won = true
		won.emit()


func _rebuild(run: bool) -> void:
	running = run
	has_won = false
	channel_on = [true, false, false, false]
	for part in parts:
		_part_layer.remove_child(part)
		part.queue_free()
	parts.clear()
	var mine: Array = placed.duplicate()
	if run:
		# Ordre canonique : à disposition égale, résultat égal, quel que soit l'ordre de pose.
		mine.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _key(a) < _key(b))
	# Les cordes s'accrochent à des pièces qui doivent déjà exister.
	for ropes: bool in [false, true]:
		for entry: Dictionary in level.get("fixed", []) + mine:
			if (entry.kind == "rope") == ropes:
				_make(entry)
	if run:
		_find_gear_pairs()


func _make(entry: Dictionary) -> Part:
	var part := Catalog.create(entry.kind)
	part.setup(entry, self, running)
	_part_layer.add_child(part)
	parts.append(part)
	return part


func _restore_entry(item: Variant) -> bool:
	if not item is Dictionary or not Catalog.INFO.has(item.get("kind", "")):
		return false
	var entry: Dictionary = (item as Dictionary).duplicate(true)
	if remaining(entry.kind) <= 0:
		return false
	if entry.kind == "rope":
		if not _rope_targets_exist(entry):
			return false
	elif not entry.get("pos") is Vector2:
		return false
	placed.append(entry)
	var part := _make(entry)
	if _is_rejected(part):
		placed.pop_back()
		_drop(part)
		return false
	return true


func _is_rejected(part: Part) -> bool:
	return not part is RopePart and not is_valid(part)


func _rope_targets_exist(entry: Dictionary) -> bool:
	var from := find_part(entry.get("from", ""))
	var to := find_part(entry.get("to", ""))
	if from == null or to == null or from == to:
		return false
	if not (from.main_body is RigidBody2D or to.main_body is RigidBody2D):
		return false
	for id: Variant in entry.get("via", []):
		if not find_part(str(id)) is PulleyPart:
			return false
	return true


func _bump_next_id() -> void:
	for entry in placed:
		var id: String = entry.get("id", "")
		if id.begins_with("p") and id.substr(1).is_valid_int():
			_next_id = maxi(_next_id, id.substr(1).to_int() + 1)


func _drop(part: Part) -> void:
	parts.erase(part)
	_part_layer.remove_child(part)
	part.queue_free()


func _key(e: Dictionary) -> String:
	var p: Vector2 = e.get("pos", Vector2.ZERO)
	return "%s|%08.1f|%08.1f|%06.1f|%s|%s" % [
		e.kind, p.x, p.y, e.get("rot", 0.0), e.get("from", ""), e.get("to", ""),
	]


func _refresh_ropes() -> void:
	for part in parts:
		if part is RopePart:
			part.refresh()


func _build_walls() -> void:
	var body := StaticBody2D.new()
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	body.physics_material_override = mat
	add_child(body)
	var w := SIZE.x + WALL * 2.0
	var h := SIZE.y + WALL * 2.0
	for r: Rect2 in [
		Rect2(SIZE.x / 2.0, -WALL / 2.0, w, WALL),
		Rect2(SIZE.x / 2.0, SIZE.y + WALL / 2.0, w, WALL),
		Rect2(-WALL / 2.0, SIZE.y / 2.0, WALL, h),
		Rect2(SIZE.x + WALL / 2.0, SIZE.y / 2.0, WALL, h),
	]:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.position
		body.add_child(col)
		_wall_shapes.append(col)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("1d2b45"))
	var minor := Color(1, 1, 1, 0.04)
	var major := Color(1, 1, 1, 0.09)
	var x := 0.0
	while x <= SIZE.x:
		draw_line(Vector2(x, 0), Vector2(x, SIZE.y), major if int(x) % 200 == 0 else minor)
		x += 40.0
	var y := 0.0
	while y <= SIZE.y:
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), major if int(y) % 200 == 0 else minor)
		y += 40.0
