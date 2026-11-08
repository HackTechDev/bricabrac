class_name OptionsPanel
extends Control
## Fenêtre d'options : volumes, langue, accessibilité. Chaque réglage appelle sa fonction dès
## qu'il change ; Échap ou « Fermer » referment la fenêtre.

signal closed

var _rows: VBoxContainer
var _title: Label
var _close: Button


func _init() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 70  # Au-dessus de l'écran titre.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_title = Label.new()
	_title.text = "Options"
	_title.add_theme_font_size_override("font_size", 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	box.add_child(_rows)
	_close = Button.new()
	_close.text = "Fermer"
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size.y = 36
	_close.pressed.connect(close)
	box.add_child(_close)
	panel.resized.connect(func() -> void: panel.position = (size - panel.size) / 2.0)
	hide()


func open() -> void:
	show()


func close() -> void:
	if visible:
		hide()
		closed.emit()


## Curseur de 0 à 100 % ; `on_change` reçoit une valeur de 0 à 1.
func add_slider(label: String, value: float, on_change: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.focus_mode = Control.FOCUS_NONE
	slider.custom_minimum_size.x = 220
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	_add_row(label, slider)
	return slider


func add_check(label: String, value: bool, on_change: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = label
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(on_change)
	_rows.add_child(check)
	return check


func add_choice(label: String, items: PackedStringArray, index: int, on_change: Callable) -> OptionButton:
	var choice := OptionButton.new()
	for item in items:
		choice.add_item(item)
	choice.select(index)
	choice.focus_mode = Control.FOCUS_NONE
	choice.custom_minimum_size.x = 220
	choice.item_selected.connect(on_change)
	_add_row(label, choice)
	return choice


func set_texts(title: String, close_text: String) -> void:
	_title.text = title
	_close.text = close_text


func _add_row(label: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size.x = 200
	row.add_child(name_label)
	row.add_child(control)
	_rows.add_child(row)


## Tant qu'elle est ouverte, la fenêtre garde le clavier : Échap la ferme, le reste est ignoré.
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if event.pressed and event.keycode == KEY_ESCAPE:
		close()
