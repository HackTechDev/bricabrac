class_name GalleryScreen
extends ColorRect
## Écran de la galerie : une ligne par niveau partagé (nom, auteur, difficulté, état chez le
## joueur), triable, avec « Jouer » qui ajoute le niveau à « Mes niveaux » après vérification.

signal play_requested(entry: Dictionary)
signal refresh_requested
signal propose_requested

var message: Label
var newest_first := false
var _entries: Array = []
var _status: Callable
var _list: VBoxContainer
var _sort: OptionButton
var _refresh: Button


func _init() -> void:
	color = Color(0.06, 0.09, 0.15)
	position = Vector2.ZERO
	size = Vector2(1280, 720)  # Taille fixe de la fenêtre du jeu.
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	outer.add_child(head)
	var title := Label.new()
	title.text = Lang.t("Galerie de niveaux partagés")
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Part.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_sort = OptionButton.new()
	_sort.add_item(Lang.t("Du plus facile au plus difficile"))
	_sort.add_item(Lang.t("Les plus récents d'abord"))
	_sort.focus_mode = Control.FOCUS_NONE
	_sort.item_selected.connect(func(index: int) -> void:
		newest_first = index == 1
		_rebuild())
	head.add_child(_sort)
	_refresh = _head_button(head, Lang.t("Actualiser en ligne"), func() -> void: refresh_requested.emit())
	_refresh.tooltip_text = Lang.t("Télécharge la dernière version de la galerie depuis le dépôt du jeu.")
	var propose := _head_button(head, Lang.t("Proposer mon niveau…"), func() -> void: propose_requested.emit())
	propose.tooltip_text = Lang.t("Ouvre une demande d'ajout sur le dépôt du jeu, avec le code du niveau de ton éditeur.")
	_head_button(head, Lang.t("Fermer (Échap)"), hide)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	outer.add_child(message)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	hide()


func _head_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


## Affiche la galerie. `status` : Callable(entry) -> String, l'état du niveau chez le joueur.
func open(entries: Array, status: Callable) -> void:
	_entries = entries
	_status = status
	_rebuild()
	show()


func set_busy(busy: bool) -> void:
	_refresh.disabled = busy


## Ligne d'un niveau, pour les tests : null s'il n'est pas affiché.
func row(key: String) -> Control:
	for child in _list.get_children():
		if child.get_meta("key", "") == key:
			return child
	return null


func play_button(key: String) -> Button:
	var line := row(key)
	return null if line == null else line.find_child(Lang.t("Jouer"), true, false) as Button


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)
	if _entries.is_empty():
		var empty := Label.new()
		empty.text = Lang.t("La galerie est vide. « Actualiser en ligne » cherche les derniers niveaux proposés.")
		_list.add_child(empty)
		return
	for entry: Dictionary in Gallery.sorted(_entries, newest_first):
		_list.add_child(_make_row(entry))


func _make_row(entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.set_meta("key", entry.key)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2a44")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override("panel", style)
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 16)
	panel.add_child(row_box)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_box.add_child(text)
	var name_label := Label.new()
	name_label.text = entry.name
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Part.GOLD)
	text.add_child(name_label)
	var by := Label.new()
	by.text = Lang.t("par %s%s  ·  %s") % [entry.author, "  ·  " + entry.added if entry.added != "" else "",
			entry.level.goal_text]
	by.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	by.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	by.custom_minimum_size.x = 100
	text.add_child(by)
	var difficulty := Label.new()
	difficulty.text = Gallery.stars(entry.difficulty)
	difficulty.custom_minimum_size.x = 150
	row_box.add_child(difficulty)
	var status := Label.new()
	status.name = "Etat"
	status.text = _status.call(entry)
	status.custom_minimum_size.x = 230
	row_box.add_child(status)
	var play := Button.new()
	play.name = "Jouer"
	play.text = Lang.t("Jouer")
	play.custom_minimum_size.x = 90
	play.focus_mode = Control.FOCUS_NONE
	play.pressed.connect(func() -> void: play_requested.emit(entry))
	row_box.add_child(play)
	return panel
