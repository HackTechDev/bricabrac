class_name CartPart
extends Part
## Chariot sur rail : un wagonnet qui ne peut que rouler le long de son rail, et emporte ce qui est
## posé dessus. Sur un rail incliné, il descend tout seul ; un choc ou un ventilateur le poussent.
## Il démarre au milieu du rail et bute sur les butoirs des extrémités.

const RAIL := Vector2(300, 8)
const CART := Vector2(70, 16)
const LIP := Vector2(6, 14)
## Hauteur du plancher du chariot au-dessus de l'axe du rail.
const RIDE := 18.0

var cart: RigidBody2D


func _build() -> void:
	var rail := make_static(0.0, 0.2)
	add_box(rail, RAIL)
	for side: float in [-1.0, 1.0]:
		add_box(rail, Vector2(8, 22), Vector2(side * (RAIL.x / 2.0 + 4.0), -7.0))
	add_visual(rail, _paint_rail)
	cart = make_rigid(2.0, 0.05, 0.8)
	cart.position = Vector2(0, -RIDE)
	cart.lock_rotation = true
	cart.linear_damp = 0.05
	add_box(cart, CART)
	for side: float in [-1.0, 1.0]:
		add_box(cart, LIP, Vector2(side * (CART.x - LIP.x) / 2.0, -(CART.y + LIP.y) / 2.0))
	add_visual(cart, _paint_cart)
	main_body = cart
	if running:
		var groove := GrooveJoint2D.new()
		# La rainure suit l'axe local +y du joint : on la couche le long du rail.
		groove.position = Vector2(-RAIL.x / 2.0 + CART.x / 2.0, -RIDE)
		groove.rotation = -PI / 2.0
		groove.length = RAIL.x - CART.x
		groove.initial_offset = (RAIL.x - CART.x) / 2.0
		add_child(groove)
		groove.node_a = groove.get_path_to(rail)
		groove.node_b = groove.get_path_to(cart)


func rotate_step() -> float:
	return 15.0


func icon_scale() -> float:
	return 0.17


func impact_sound() -> String:
	return "knock"


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Roule le long de son rail et emporte ce qu'il porte."))
	return lines


func paint_icon(c: CanvasItem) -> void:
	_paint_rail(c)
	c.draw_set_transform(Vector2(0, -RIDE))
	_paint_cart(c)
	c.draw_set_transform(Vector2.ZERO)


func _paint_rail(c: CanvasItem) -> void:
	box(c, Rect2(-RAIL / 2.0, RAIL), Color("5b6573"))
	var x := -RAIL.x / 2.0 + 10.0
	while x < RAIL.x / 2.0:
		c.draw_line(Vector2(x, -RAIL.y / 2.0), Vector2(x, RAIL.y / 2.0), INK, 1.0)
		x += 20.0
	for side: float in [-1.0, 1.0]:
		box(c, Rect2(side * (RAIL.x / 2.0 + 4.0) - 4.0, -18.0, 8.0, 22.0), Color("d9a441"))


func _paint_cart(c: CanvasItem) -> void:
	box(c, Rect2(-CART / 2.0, CART), Color("c0503f"))
	for side: float in [-1.0, 1.0]:
		box(c, Rect2(Vector2(side * (CART.x - LIP.x) / 2.0, -(CART.y + LIP.y) / 2.0) - LIP / 2.0, LIP), Color("c0503f"))
		var wheel := Vector2(side * 22.0, CART.y / 2.0 + 2.0)
		c.draw_circle(wheel, 6.0, STEEL)
		c.draw_arc(wheel, 6.0, 0.0, TAU, 16, INK, 2.0)
