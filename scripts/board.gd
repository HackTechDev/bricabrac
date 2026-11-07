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
var sfx := Sfx.new()
var probe := CircleShape2D.new()

var _next_id := 1
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
	placed.clear()
	_next_id = 1
	_rebuild(false)
	inventory_changed.emit()


func start() -> void:
	# Ordre canonique : à disposition égale, résultat égal, quel que soit l'ordre de pose.
	placed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _key(a) < _key(b))
	_rebuild(true)


func stop() -> void:
	_rebuild(false)


func clear_placed() -> void:
	placed.clear()
	_rebuild(false)
	inventory_changed.emit()


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
		if other != part and part.overlaps_part(other):
			return false
	return true


func part_at(point: Vector2) -> Part:
	# Les objets passent avant les cordes qui les traversent.
	for ropes: bool in [false, true]:
		for i in range(parts.size() - 1, -1, -1):
			if (parts[i] is RopePart) == ropes and parts[i].hit_test(point):
				return parts[i]
	return null


func activate_channel(channel: int) -> void:
	for part in parts.duplicate():
		if part.channel == channel:
			part.set_powered(true)


## Objet créé pendant la simulation, hors disposition.
func spawn(entry: Dictionary) -> void:
	_spawn_now.call_deferred(entry)


func _spawn_now(entry: Dictionary) -> void:
	if running:
		_make(entry)


func _physics_process(_delta: float) -> void:
	if not running or has_won:
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
	for part in parts:
		_part_layer.remove_child(part)
		part.queue_free()
	parts.clear()
	var layout: Array = level.get("fixed", []) + placed
	# Les cordes s'accrochent à des pièces qui doivent déjà exister.
	for ropes: bool in [false, true]:
		for entry: Dictionary in layout:
			if (entry.kind == "rope") == ropes:
				_make(entry)


func _make(entry: Dictionary) -> Part:
	var part := Catalog.create(entry.kind)
	part.setup(entry, self, running)
	_part_layer.add_child(part)
	parts.append(part)
	return part


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
