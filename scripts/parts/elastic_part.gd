class_name ElasticPart
extends RopePart
## Élastique : se pose comme une corde, mais s'étire. Au-delà de sa longueur de repos, il tire en
## proportion de l'allongement, comme un ressort ; en deçà, il pend sans agir.
## R règle la tension de départ : un élastique tendu à 50 % ne mesure au repos que la moitié de sa
## longueur de pose, de quoi faire une catapulte.

const ELASTIC_COLOR := Color("e9a23b")
## Raideur, en force par pixel d'allongement, et amortissement le long de l'élastique.
const STIFF := 30.0
const DAMP := 4.0


func _build() -> void:
	add_visual(self, paint)
	if running and _resolve():
		var path := points()
		rest_length = _measure(path) * (1.0 - tension())
		_first_span = path[0].distance_to(path[1])


func tension() -> float:
	return entry.get("tension", 0.0) / 100.0


func setting() -> Dictionary:
	return {"key": "tension", "step": 10.0, "min": 0.0, "max": 70.0, "default": 0.0, "label": "Tension (R)"}


func describe() -> PackedStringArray:
	var lines := PackedStringArray()
	var via: int = entry.get("via", []).size()
	if via > 0:
		lines.append("Passe par %d poulie(s)" % via)
	lines.append("Tendu à %d %% au départ" % roundi(tension() * 100.0) if tension() > 0.0
			else "Juste tendu (R : le tendre davantage)")
	return lines


func _physics_process(_delta: float) -> void:
	if _cut or _a == null:
		return
	if not _attached(_a) or not _attached(_b):
		_cut = true
		refresh()
		return
	var path := points()
	var stretch := _measure(path) - rest_length
	max_stretch = maxf(max_stretch, stretch)
	_turn_pulleys(path)
	refresh()
	if stretch <= 0.0:
		return
	var last := path.size() - 1
	var a := End.new(_a.main_body, board.to_global(path[0]), (path[1] - path[0]).normalized())
	var b := End.new(_b.main_body, board.to_global(path[last]), (path[last - 1] - path[last]).normalized())
	var force := STIFF * stretch + DAMP * (a.pull_rate() + b.pull_rate())
	if force <= 0.0:
		return
	var impulse := force / Engine.physics_ticks_per_second
	a.apply(impulse)
	b.apply(impulse)


func paint(c: CanvasItem) -> void:
	var path := points()
	if path.size() < 2:
		return
	var col := Color.WHITE if selected else ELASTIC_COLOR
	# Plus il est étiré, plus il s'amincit.
	var length := _measure(path)
	var rest := rest_length if running else length * (1.0 - tension())
	var width := clampf(4.0 * rest / maxf(length, 1.0), 1.5, 5.0)
	for i in range(1, path.size()):
		c.draw_line(path[i - 1], path[i], col, width)
	c.draw_circle(path[0], 4.0, col)
	c.draw_circle(path[path.size() - 1], 4.0, col)


func paint_icon(c: CanvasItem) -> void:
	var zig := PackedVector2Array()
	for i in 7:
		zig.append(Vector2(-15.0 + i * 5.0, -6.0 if i % 2 else 6.0))
	c.draw_polyline(zig, ELASTIC_COLOR, 3.0)
