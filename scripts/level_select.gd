class_name LevelSelect
extends ColorRect
## Écran de sélection des niveaux : une vignette par niveau, regroupées par monde. Les vignettes
## sont de vrais plateaux en miniature, rendus une seule fois à la première ouverture.

signal chosen(index: int)
signal import_requested
signal title_requested

const THUMB := Vector2(192, 118)
const COLUMNS := 5

var _levels: Array = []
## Vignettes et lignes d'état, par indice de niveau (les niveaux cachés n'en ont pas).
var _cards := {}
var _status := {}
var _thumbs_built := false
var _thumb_rects := {}


func setup(levels: Array) -> void:
	_levels = levels
	color = Color(0.06, 0.09, 0.15)
	position = Vector2.ZERO
	size = Vector2(1280, 720)  # Taille fixe de la fenêtre du jeu.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	var title := Label.new()
	title.text = "Choisis un niveau"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Part.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var importer := Button.new()
	importer.text = "Importer un niveau…"
	importer.focus_mode = Control.FOCUS_NONE
	importer.pressed.connect(func() -> void:
		hide()
		import_requested.emit())
	head.add_child(importer)
	var to_title := Button.new()
	to_title.text = "Écran titre"
	to_title.focus_mode = Control.FOCUS_NONE
	to_title.pressed.connect(func() -> void: title_requested.emit())
	head.add_child(to_title)
	var close := Button.new()
	close.text = "Fermer (Échap)"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	head.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var groups: Array = []
	for w: Dictionary in LevelData.WORLDS:
		groups.append([w.name, w.id])
	groups.append(["Création libre", ""])
	for group: Array in groups:
		var indices: Array[int] = []
		for i in levels.size():
			if levels[i].get("world", "") == group[1] and not levels[i].get("hidden", false):
				indices.append(i)
		if indices.is_empty():
			continue
		var header := Label.new()
		header.text = group[0]
		header.add_theme_font_size_override("font_size", 20)
		list.add_child(header)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		list.add_child(grid)
		for i in indices:
			grid.add_child(_make_card(i))
	hide()


func _make_card(index: int) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = THUMB + Vector2(16, 64)
	card.pressed.connect(func() -> void:
		hide()
		chosen.emit(index))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(8, 8)
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = THUMB
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(thumb)
	_thumb_rects[index] = thumb
	var name_label := Label.new()
	name_label.text = "%d. %s" % [index + 1, _levels[index].name]
	name_label.custom_minimum_size.x = THUMB.x
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	var status := Label.new()
	status.add_theme_font_size_override("font_size", 13)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status)
	_cards[index] = card
	_status[index] = status
	return card


## Ouvre l'écran ; `statuses` donne, par niveau, la ligne d'état (terminé, étoiles).
func open(current: int, statuses: Array) -> void:
	for i: int in _cards:
		_status[i].text = statuses[i]
		_cards[i].modulate = Color(1.15, 1.15, 0.85) if i == current else Color.WHITE
	if not _thumbs_built:
		_thumbs_built = true
		for i: int in _thumb_rects:
			_thumb_rects[i].texture = _render_thumb(_levels[i])
	show()


func card(index: int) -> Button:
	return _cards[index]


func status_text(index: int) -> String:
	return _status[index].text


## Plateau miniature : le décor du niveau, dessiné dans une sous-fenêtre rendue une seule fois.
func _render_thumb(level: Dictionary) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(Board.SIZE)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	add_child(vp)
	var mini := Board.new()
	vp.add_child(mini)
	mini.load_level(level.duplicate(true))
	mini.set_process(false)
	mini.sfx.process_mode = Node.PROCESS_MODE_DISABLED
	# La sous-fenêtre a sa propre physique : on la fige, le dessin suffit.
	mini.process_mode = Node.PROCESS_MODE_DISABLED
	return vp.get_texture()
