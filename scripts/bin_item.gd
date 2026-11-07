class_name BinItem
extends PanelContainer
## Ligne du bac à pièces : on la saisit pour glisser une pièce sur le plateau.

signal grabbed(kind: String)

var kind := ""
var _count_label: Label
var _available := false


func setup(p_kind: String) -> void:
	kind = p_kind
	var info: Dictionary = Catalog.INFO[kind]
	tooltip_text = info.desc
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var icon := PartIcon.new()
	icon.setup(kind)
	row.add_child(icon)
	var label := Label.new()
	label.text = info.label
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_count_label = Label.new()
	row.add_child(_count_label)


func update_count(count: int, editable: bool) -> void:
	_count_label.text = "x%d" % count
	_available = count > 0 and editable
	modulate.a = 1.0 if _available else 0.4


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and _available:
		grabbed.emit(kind)
		accept_event()
