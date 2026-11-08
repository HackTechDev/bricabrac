class_name TubePart
extends Part
## Tuyau droit : deux parois parallèles, de la largeur du tuyau coudé, pour guider les billes
## en ligne droite. Il pivote par crans de 15° ; + et − (ou le menu du clic droit) règlent sa
## longueur.

## Largeur intérieure, celle du coude, pour qu'ils se raccordent.
const INNER := PipePart.OUTER - PipePart.INNER
const WALL := PipePart.WALL
const DEFAULT_LENGTH := 160.0


func _build() -> void:
	var body := make_static(0.05, 0.05)
	for side: float in [-1.0, 1.0]:
		add_box(body, Vector2(_length(), WALL), Vector2(0, side * (INNER + WALL) / 2.0))
	add_visual(body, paint)


func _length() -> float:
	return entry.get("len", DEFAULT_LENGTH)


func rotate_step() -> float:
	return 15.0


func size_setting() -> Dictionary:
	return {"key": "len", "step": 20.0, "min": 80.0, "max": 400.0, "default": DEFAULT_LENGTH}


func icon_scale() -> float:
	return 0.5


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Longueur : %d px (+ et − pour la changer).") % int(_length()))
	return lines


func paint(c: CanvasItem) -> void:
	var half := _length() / 2.0
	c.draw_rect(Rect2(-half, -INNER / 2.0, _length(), INNER), Color(0.55, 0.75, 0.6, 0.18))
	for side: float in [-1.0, 1.0]:
		var y := side * (INNER + WALL) / 2.0
		box(c, Rect2(-half, y - WALL / 2.0, _length(), WALL), Color("5f9e6e"))
	# Bagues aux deux bouts, comme sur le coude.
	for x: float in [-half, half - 6.0]:
		box(c, Rect2(x, -INNER / 2.0 - WALL - 2.0, 6.0, INNER + 2.0 * WALL + 4.0), Color("4d8a5c"))
