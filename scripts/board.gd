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

var _part_layer: Node2D
var _wall_shapes: Array[CollisionShape2D] = []
var _probe := CircleShape2D.new()


func _ready() -> void:
	_probe.radius = 3.0
	_build_walls()
	_part_layer = Node2D.new()
	add_child(_part_layer)


func load_level(p_level: Dictionary) -> void:
	level = p_level
	placed.clear()
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
	var entry := {"kind": kind, "pos": snap(pos), "rot": 0.0, "dir": 1}
	var part := _make(entry)
	if part.uses_channel():
		entry.channel = part.channel_range().x
		part.channel = entry.channel
		part.powered = part.channel == 0
	placed.append(entry)
	part.refresh()
	inventory_changed.emit()
	return part


func remove(part: Part) -> void:
	placed.erase(part.entry)
	_drop(part)
	inventory_changed.emit()


## Recrée la pièce après un changement de sa disposition.
func rebuild_part(part: Part) -> Part:
	var entry := part.entry
	_drop(part)
	return _make(entry)


func move_part(part: Part, pos: Vector2) -> void:
	part.entry.pos = snap(pos)
	part.position = part.entry.pos


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
	var xform := global_transform * Transform2D(0.0, point)
	for i in range(parts.size() - 1, -1, -1):
		if parts[i].overlaps_shape(_probe, xform):
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
	for entry in level.get("fixed", []):
		_make(entry)
	for entry in placed:
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
	var p: Vector2 = e.pos
	return "%s|%08.1f|%08.1f|%06.1f" % [e.kind, p.x, p.y, e.get("rot", 0.0)]


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
