class_name Effects
extends Node2D
## Particules décoratives (éclats, fumée, poussière, gouttes, étincelles), dessinées par-dessus les pièces. Elles ne
## touchent rien et n'influent pas sur la simulation ; leur hasard a sa propre graine.

const MAX_PARTICLES := 400
const GRAVITY := 600.0

## Désactivées par l'option « réduire les animations ».
static var enabled := true

var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	set_process(false)


## Éclats d'un ballon qui éclate.
func shards(at: Vector2, color: Color) -> void:
	for i in 12:
		var v := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(120.0, 300.0)
		_add({"pos": at, "vel": v, "life": _rng.randf_range(0.45, 0.75), "size": _rng.randf_range(4.0, 7.0),
				"color": color, "kind": "shard", "spin": _rng.randf_range(-12.0, 12.0), "gravity": 1.0})


## Fumée qui sort d'un canon dans la direction `axis`.
func smoke(at: Vector2, axis: Vector2) -> void:
	for i in 9:
		var v := axis * _rng.randf_range(40.0, 160.0) + Vector2.from_angle(_rng.randf() * TAU) * 30.0
		_add({"pos": at, "vel": v, "life": _rng.randf_range(0.7, 1.1), "size": _rng.randf_range(5.0, 8.0),
				"color": Color(0.85, 0.85, 0.88), "kind": "smoke", "gravity": -0.08})


## Poussière d'un choc ; `strength` de 0 à 1, `normal` orienté hors de la surface touchée.
func dust(at: Vector2, normal: Vector2, strength: float) -> void:
	var amount := int(clampf(strength, 0.2, 1.0) * 8.0)
	for i in amount:
		var spread := normal.rotated(_rng.randf_range(-1.3, 1.3))
		_add({"pos": at, "vel": spread * _rng.randf_range(40.0, 120.0) * clampf(strength + 0.4, 0.5, 1.4),
				"life": _rng.randf_range(0.3, 0.55), "size": _rng.randf_range(2.0, 3.5),
				"color": Color(0.85, 0.78, 0.62), "kind": "dust", "gravity": 0.25})


## Gouttes d'un objet qui frappe la surface de l'eau ; `strength` de 0 à 1.
func splash(at: Vector2, strength: float) -> void:
	var amount := int(clampf(strength, 0.25, 1.0) * 10.0)
	for i in amount:
		var v := Vector2.UP.rotated(_rng.randf_range(-0.8, 0.8)) * _rng.randf_range(90.0, 260.0) \
				* clampf(strength + 0.3, 0.5, 1.2)
		_add({"pos": at + Vector2(_rng.randf_range(-8.0, 8.0), 0.0), "vel": v,
				"life": _rng.randf_range(0.35, 0.6), "size": _rng.randf_range(2.0, 3.5),
				"color": Color(0.6, 0.85, 1.0), "kind": "drop", "gravity": 1.0})


## Étincelles là où deux engrenages rapides se touchent, lancées le long de `along`.
func sparks(at: Vector2, along: Vector2) -> void:
	for i in 3:
		var v := along.rotated(_rng.randf_range(-0.5, 0.5)) * _rng.randf_range(80.0, 200.0)
		_add({"pos": at, "vel": v, "life": _rng.randf_range(0.18, 0.32), "size": _rng.randf_range(1.5, 2.5),
				"color": Color(1.0, 0.8, 0.35), "kind": "spark", "gravity": 0.6})


func clear() -> void:
	_particles.clear()
	set_process(false)
	queue_redraw()


func count() -> int:
	return _particles.size()


func _add(p: Dictionary) -> void:
	if not enabled or _particles.size() >= MAX_PARTICLES:
		return
	p.age = 0.0
	p.angle = _rng.randf() * TAU
	_particles.append(p)
	set_process(true)


func _process(delta: float) -> void:
	var alive: Array[Dictionary] = []
	for p in _particles:
		p.age += delta
		if p.age >= p.life:
			continue
		p.vel.y += GRAVITY * p.gravity * delta
		if p.kind == "smoke":
			p.vel *= 1.0 - minf(2.5 * delta, 1.0)
		p.pos += p.vel * delta
		p.angle += p.get("spin", 0.0) * delta
		alive.append(p)
	_particles = alive
	if _particles.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var t: float = p.age / p.life
		var col: Color = p.color
		match p.kind:
			"shard":
				col.a = 1.0 - t
				var s: float = p.size
				var tri := PackedVector2Array()
				for k in 3:
					tri.append(p.pos + Vector2.from_angle(p.angle + TAU * k / 3.0) * s * (1.0 if k else 1.6))
				draw_colored_polygon(tri, col)
			"spark":
				col.a = 1.0 - t
				draw_line(p.pos, p.pos - p.vel.normalized() * p.size * 3.0, col, p.size)
			"drop":
				col.a = 0.85 * (1.0 - t * t)
				draw_circle(p.pos, p.size, col)
			"smoke":
				col.a = 0.45 * (1.0 - t)
				draw_circle(p.pos, p.size * (1.0 + 1.8 * t), col)
			_:
				col.a = 0.8 * (1.0 - t)
				draw_circle(p.pos, p.size * (1.0 - 0.5 * t), col)
