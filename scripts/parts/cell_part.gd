class_name CellPart
extends Part
## Cellule photoélectrique : allume son canal tant qu'une lampe l'éclaire, l'éteint dans l'ombre.
## Un objet qui coupe le faisceau lui fait de l'ombre. Miroir : l'inverse, elle allume son canal
## quand la lumière disparaît (une barrière lumineuse).

const SIZE := Vector2(40, 22)
const LENS := Vector2(0, -SIZE.y / 2.0 - 4.0)
## Lumière qu'il faut pour qu'elle se déclenche.
const THRESHOLD := 0.5

var lit := false
var _known := false


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func rotate_step() -> float:
	return 45.0


func can_flip() -> bool:
	return true


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func icon_scale() -> float:
	return 0.8


func is_animated() -> bool:
	return true


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Allume son canal quand une lampe l'éclaire.") if dir > 0
			else Lang.t("Allume son canal quand on lui coupe la lumière."))
	return lines


func _physics_process(delta: float) -> void:
	super(delta)
	var now := board.light_at(board.to_local(to_global(LENS)), [main_body.get_rid()]) >= THRESHOLD
	if _known and now == lit:
		return
	_known = true
	lit = now
	board.set_channel(channel, lit == (dir > 0))
	refresh()


func paint(c: CanvasItem) -> void:
	var half := SIZE / 2.0
	box(c, Rect2(-half.x, -half.y, SIZE.x, SIZE.y), STEEL)
	var eye := Color("ffe9a0") if lit else Color("3a4458")
	c.draw_circle(LENS, 9.0, eye)
	c.draw_arc(LENS, 9.0, PI, TAU, 12, INK, 2.0)
	c.draw_line(LENS + Vector2(-9, 0), LENS + Vector2(9, 0), INK, 2.0)
	# Petite flèche : vers le haut, allume à la lumière ; vers le bas, allume dans l'ombre.
	var tip := Vector2(half.x - 8.0, -4.0 * dir)
	poly(c, PackedVector2Array([tip, tip + Vector2(-4, 5 * dir), tip + Vector2(4, 5 * dir)]), INK)
	paint_channel(c, Vector2(-10, 3))
