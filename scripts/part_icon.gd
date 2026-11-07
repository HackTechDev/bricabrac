class_name PartIcon
extends Control
## Vignette : réutilise le dessin de la pièce, sans physique.

var _part: Part


func setup(kind: String) -> void:
	_part = Catalog.create(kind)
	custom_minimum_size = Vector2(52, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _exit_tree() -> void:
	if _part != null:
		_part.free()
		_part = null


func _draw() -> void:
	var s := _part.icon_scale()
	draw_set_transform(size / 2.0, 0.0, Vector2(s, s))
	_part.paint_icon(self)
