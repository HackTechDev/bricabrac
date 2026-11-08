class_name MagnetPart
extends Part
## Aimant : attire les objets métalliques (boulet, bille) à portée de ses pôles.
## L'attraction est une accélération qui faiblit avec la distance : un boulet est aussi bien attiré
## qu'une bille. Canal 0 : toujours actif.

const SIZE := Vector2(56, 44)
const RANGE := 260.0
const STRENGTH := 2600.0
## Point d'attraction : devant les pôles, dans le repère de la pièce.
const POLE := Vector2(0, -SIZE.y / 2.0)


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func _physics_process(delta: float) -> void:
	super(delta)
	if not powered:
		return
	var pole := to_global(POLE)
	for part in board.parts:
		if not part.is_metal() or not part.main_body is RigidBody2D:
			continue
		var body := part.main_body as RigidBody2D
		if not is_instance_valid(body):
			continue
		var offset := pole - body.global_position
		var distance := offset.length()
		if distance < RANGE and distance > 1.0:
			var pull := STRENGTH * pow(1.0 - distance / RANGE, 2.0)
			body.apply_central_force(offset / distance * pull * body.mass)


func channel_range() -> Vector2i:
	return Vector2i(0, 3)


func rotate_step() -> float:
	return 45.0


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.6


func describe() -> PackedStringArray:
	var lines := super()
	lines.append("Attire le boulet et la bille jusqu'à %d px." % RANGE)
	return lines


func paint(c: CanvasItem) -> void:
	if not running:
		c.draw_arc(POLE, RANGE, 0.0, TAU, 64, Color(1, 1, 1, 0.08), 1.0)
	elif powered:
		for i in 3:
			var r := fposmod(anim * 120.0 + i * RANGE / 3.0, RANGE)
			c.draw_arc(POLE, RANGE - r, PI + 0.4, TAU - 0.4, 32, Color(1, 0.4, 0.4, 0.25 * r / RANGE), 2.0)
	var half := SIZE / 2.0
	# Fer à cheval, pôles vers le haut.
	box(c, Rect2(-half.x, -half.y + 14.0, SIZE.x, SIZE.y - 14.0), Color("c94b4b"))
	box(c, Rect2(-half.x, -half.y, 18.0, 16.0), Color("dfe6ef"))
	box(c, Rect2(half.x - 18.0, -half.y, 18.0, 16.0), Color("dfe6ef"))
	c.draw_rect(Rect2(-half.x + 18.0, -half.y, SIZE.x - 36.0, 18.0), Color("1d2b45"))
	paint_channel(c, Vector2(0, 8))
