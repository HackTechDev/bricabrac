class_name CandlePart
extends Part
## Bougie : sa chaleur monte et fait éclater les ballons qui passent au-dessus de la flamme, si
## rien ne s'interpose. Canal 0 : allumée dès le départ ; canal 1 à 3 : s'allume avec son canal.
## Le vent la souffle : celui du niveau ou d'un ventilateur, s'il atteint la flamme sans obstacle.
## Éteinte, elle ne se rallume plus de l'essai.

const SIZE := Vector2(22, 48)
## Colonne de chaleur au-dessus de la flamme.
const HEAT_HEIGHT := 240.0
const HEAT_WIDTH := 44.0
const FLAME := Vector2(0, -SIZE.y / 2.0 - 10.0)
## Temps passé dans la chaleur avant d'éclater.
const HEAT_TIME := 0.15

## Soufflée par le vent pendant cet essai.
var blown := false
## Ballon → temps déjà passé au-dessus de la flamme.
var _heat := {}


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_lit():
		return
	var flame := to_global(FLAME)
	if board.wind_reaches(board.to_local(flame), self):
		blown = true
		_heat.clear()
		board.effects.smoke(board.to_local(flame), Vector2.UP)
		board.sfx.play("snip")
		refresh()
		return
	for part in board.parts:
		if not part is BalloonPart or (part as BalloonPart).popped:
			continue
		var balloon := part as BalloonPart
		if not _heats(balloon, flame):
			_heat.erase(balloon)
			continue
		_heat[balloon] = _heat.get(balloon, 0.0) + delta
		if _heat[balloon] >= HEAT_TIME:
			balloon.pop()


func _heats(balloon: BalloonPart, flame: Vector2) -> bool:
	var at := balloon.body.global_position
	var rise := flame.y - at.y + BalloonPart.RADIUS
	if rise < 0.0 or rise > HEAT_HEIGHT or absf(at.x - flame.x) > HEAT_WIDTH / 2.0 + BalloonPart.RADIUS:
		return false
	var query := PhysicsRayQueryParameters2D.create(flame, at, Part.LAYER_WORLD)
	query.exclude = [main_body.get_rid(), balloon.body.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Allumée et pas encore soufflée.
func is_lit() -> bool:
	return powered and not blown


func light_sources() -> Array:
	if not is_lit():
		return []
	return [{"pos": board.to_local(to_global(FLAME)), "range": 120.0, "strength": 0.8}]


func on_powered() -> void:
	if running and powered:
		board.sfx.play("tick")


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.7


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Fait éclater les ballons jusqu'à %d px au-dessus de la flamme.") % HEAT_HEIGHT)
	lines.append(Lang.t("Le vent ou un ventilateur la souffle, sauf derrière un abri."))
	return lines


func paint(c: CanvasItem) -> void:
	var half := SIZE / 2.0
	if not running:
		c.draw_rect(Rect2(FLAME.x - HEAT_WIDTH / 2.0, FLAME.y - HEAT_HEIGHT, HEAT_WIDTH, HEAT_HEIGHT),
				Color(1, 0.6, 0.2, 0.06))
	elif is_lit():
		for i in 3:
			var y := fposmod(anim * 90.0 + i * HEAT_HEIGHT / 3.0, HEAT_HEIGHT)
			var x := sin(anim * 6.0 + i * 2.0) * 6.0
			c.draw_arc(FLAME + Vector2(x, -y), 8.0, PI + 0.6, TAU - 0.6, 10,
					Color(1, 0.7, 0.3, 0.3 * (1.0 - y / HEAT_HEIGHT)), 2.0)
	box(c, Rect2(-half.x, -half.y, SIZE.x, SIZE.y), Color("f2ead8"))
	c.draw_line(Vector2(0, -half.y), Vector2(0, -half.y - 5.0), INK, 2.0)
	if is_lit() or not running:
		var flicker := 1.0 + 0.12 * sin(anim * 23.0)
		var tip := FLAME + Vector2(0, -9.0 * flicker)
		poly(c, PackedVector2Array([FLAME + Vector2(-5, 4), tip, FLAME + Vector2(5, 4)]),
				Color("ffb347") if is_lit() else Color(1, 0.7, 0.3, 0.45))
		c.draw_circle(FLAME + Vector2(0, 2), 3.0, Color("fff3b0"))
	paint_channel(c, Vector2(0, 8))
