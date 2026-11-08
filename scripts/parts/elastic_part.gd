class_name ElasticPart
extends RopePart
## Élastique : se pose comme une corde, mais s'étire. Au-delà de sa longueur de repos, il tire en
## proportion de l'allongement, comme un ressort ; en deçà, il pend sans agir.
## R règle la tension de départ : un élastique tendu à 50 % ne mesure au repos que la moitié de sa
## longueur de pose, de quoi faire une catapulte.

const ELASTIC_COLOR := Color("e9a23b")
## Raideur, en force par pixel d'allongement, et amortissement de l'allongement.
const STIFF := 30.0
const DAMP := 4.0


func _rest_for(length: float) -> float:
	return length * (1.0 - tension())


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
	if not _advance():
		return
	var stretch := _length - rest_length
	max_stretch = maxf(max_stretch, stretch)
	refresh()
	if stretch <= 0.0:
		return
	var ends := _ends()
	var rate := 0.0
	for end in ends:
		rate += end.pull_rate()
	# L'amortissement freine l'allongement, mais pas la détente : relâché, l'élastique claque
	# et lance ce qu'il tient, comme une fronde.
	var force := STIFF * stretch + DAMP * maxf(rate, 0.0)
	if force <= 0.0:
		return
	var impulse := force / Engine.physics_ticks_per_second
	for end in ends:
		end.apply(impulse)


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
