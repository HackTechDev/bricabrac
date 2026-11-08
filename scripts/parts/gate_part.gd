class_name GatePart
extends Part
## Trappe (horizontale) et porte (verticale) : s'ouvrent quand leur canal s'allume, se referment
## quand il s'éteint. Le panneau pivote vraiment autour de sa charnière : il lâche ce qu'il porte
## et repousse ce qu'il rencontre. La position de la pièce est celle de la charnière.

const LENGTH := 120.0
const THICKNESS := 12.0
const SWING_TIME := 0.3

var panel: AnimatableBody2D
## 0 = fermé, 1 = ouvert.
var opening := 0.0


func _build() -> void:
	panel = AnimatableBody2D.new()
	panel.physics_material_override = _material(0.0, 1.0)
	panel.set_meta("part", self)
	add_child(panel)
	main_body = panel
	add_box(panel, _panel_size(), _panel_offset())
	add_visual(panel, _paint_panel)
	add_visual(self, _paint_hinge)


func _physics_process(delta: float) -> void:
	var target := 1.0 if powered else 0.0
	opening = move_toward(opening, target, delta / SWING_TIME)
	# La trappe bascule vers le bas ; la porte s'écarte vers la droite (vers la gauche en miroir).
	var swing := -1.0 if _is_door() else 1.0
	panel.rotation = opening * PI / 2.0 * dir * swing


func on_powered() -> void:
	board.sfx.play("tick")


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func can_flip() -> bool:
	return true


func rotate_step() -> float:
	return 90.0


func icon_scale() -> float:
	return 0.35


func describe() -> PackedStringArray:
	var lines := super()
	lines.append("S'ouvre quand son canal s'allume.")
	return lines


func paint_icon(c: CanvasItem) -> void:
	c.draw_set_transform(-_panel_offset())
	_paint_panel(c)
	_paint_hinge(c)
	c.draw_set_transform(Vector2.ZERO)


func _is_door() -> bool:
	return kind == "door"


func _panel_size() -> Vector2:
	return Vector2(THICKNESS, LENGTH) if _is_door() else Vector2(LENGTH, THICKNESS)


## La trappe s'étend vers la droite de sa charnière (vers la gauche en miroir) ; la porte pend.
func _panel_offset() -> Vector2:
	return Vector2(0, LENGTH / 2.0) if _is_door() else Vector2(LENGTH / 2.0 * dir, 0)


func _paint_panel(c: CanvasItem) -> void:
	var r := Rect2(_panel_offset() - _panel_size() / 2.0, _panel_size())
	box(c, r, Color("8c6a43"))
	var stripes := 4
	for i in stripes:
		var t := (i + 0.5) / stripes
		var p := r.position + r.size * t
		if _is_door():
			c.draw_line(Vector2(r.position.x, p.y), Vector2(r.end.x, p.y), INK, 1.0)
		else:
			c.draw_line(Vector2(p.x, r.position.y), Vector2(p.x, r.end.y), INK, 1.0)
	paint_channel(c, _panel_offset())


func _paint_hinge(c: CanvasItem) -> void:
	c.draw_circle(Vector2.ZERO, 7.0, STEEL)
	c.draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, INK, 2.0)
