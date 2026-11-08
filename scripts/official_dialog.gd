class_name OfficialDialog
extends PopupPanel
## Niveaux du jeu dans l'éditeur (outil de développement, quand le dossier `levels/` est
## modifiable) : liste des fichiers à ouvrir, et fiche à remplir pour enregistrer le plan de
## travail comme niveau du jeu.

signal opened(path: String)
signal save_confirmed(meta: Dictionary)

var list: ItemList
var id_edit: LineEdit
var world_button: OptionButton
var challenge_check: CheckBox
var intro_edit: LineEdit
var hint_edit: LineEdit
var par_spin: SpinBox
var file_label: Label
var message: Label
var _paths: PackedStringArray = []
var _list_box: VBoxContainer
var _form_box: VBoxContainer
var _meta := {}


func _init() -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(560, 0)
	add_child(col)
	_list_box = VBoxContainer.new()
	col.add_child(_list_box)
	_list_box.add_child(_title(Lang.t("Ouvrir un niveau du jeu")))
	list = ItemList.new()
	list.custom_minimum_size = Vector2(540, 380)
	list.item_activated.connect(_open)
	_list_box.add_child(list)
	var open := Button.new()
	open.text = Lang.t("Ouvrir dans l'éditeur")
	open.pressed.connect(func() -> void:
		if not list.get_selected_items().is_empty():
			_open(list.get_selected_items()[0]))
	_list_box.add_child(open)

	_form_box = VBoxContainer.new()
	col.add_child(_form_box)
	_form_box.add_child(_title(Lang.t("Enregistrer comme niveau du jeu")))
	var grid := GridContainer.new()
	grid.columns = 2
	_form_box.add_child(grid)
	id_edit = _field(grid, Lang.t("Identifiant"), LineEdit.new())
	id_edit.placeholder_text = Lang.t("minuscules, chiffres et _")
	world_button = _field(grid, Lang.t("Monde"), OptionButton.new())
	for world: Dictionary in LevelData.WORLDS:
		if world.id != "perso":
			world_button.add_item(world.name)
			world_button.set_item_metadata(world_button.item_count - 1, world.id)
	intro_edit = _field(grid, Lang.t("Introduction"), LineEdit.new())
	hint_edit = _field(grid, Lang.t("Indice"), LineEdit.new())
	par_spin = _field(grid, Lang.t("Temps « Rapide » (s)"), SpinBox.new())
	par_spin.min_value = 0.0
	par_spin.max_value = 60.0
	par_spin.step = 0.5
	challenge_check = _field(grid, Lang.t("Niveau défi"), CheckBox.new())
	challenge_check.text = Lang.t("fermé tant que le monde n'a pas toutes ses étoiles")
	file_label = Label.new()
	file_label.add_theme_font_size_override("font_size", 13)
	_form_box.add_child(file_label)
	var save := Button.new()
	save.text = Lang.t("Enregistrer le fichier")
	save.pressed.connect(_confirm)
	_form_box.add_child(save)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color("f0a070"))
	col.add_child(message)


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Part.GOLD)
	return label


func _field(grid: GridContainer, text: String, control: Control) -> Variant:
	var label := Label.new()
	label.text = text
	grid.add_child(label)
	control.custom_minimum_size.x = 380
	grid.add_child(control)
	return control


## Liste des niveaux du jeu : `files` vient de LevelFile.list_dir.
func show_list(files: Array) -> void:
	_list_box.visible = true
	_form_box.visible = false
	message.text = ""
	list.clear()
	_paths.clear()
	for file: Dictionary in files:
		var level: Dictionary = file.level
		list.add_item(Lang.t("%s  —  %s (%s)") % [file.path.get_file().get_basename(), level.get("name", "?"),
				LevelData.world(level.get("world", "")).name])
		_paths.append(file.path)
	popup_centered(Vector2i(580, 470))


## Fiche du niveau à enregistrer ; `meta` : valeurs de départ (id, world, intro, hint, par_time,
## challenge, tutorial), `path` : fichier qui sera écrit si l'identifiant ne change pas.
func show_form(values: Dictionary, path: String) -> void:
	_list_box.visible = false
	_form_box.visible = true
	message.text = ""
	_meta = values.duplicate(true)
	id_edit.text = values.get("id", "")
	for i in world_button.item_count:
		if world_button.get_item_metadata(i) == values.get("world", "atelier"):
			world_button.select(i)
	intro_edit.text = values.get("intro", "")
	hint_edit.text = values.get("hint", "")
	par_spin.value = values.get("par_time", 0.0)
	challenge_check.button_pressed = values.get("challenge", false)
	file_label.text = Lang.t("Fichier : ") + (path.get_file() if path != "" else Lang.t("nouveau, numéroté après les autres"))
	popup_centered(Vector2i(580, 330))


func meta() -> Dictionary:
	var out := _meta.duplicate(true)
	out.merge({
		"id": id_edit.text.strip_edges(),
		"world": world_button.get_item_metadata(maxi(world_button.selected, 0)),
		"intro": intro_edit.text.strip_edges(),
		"hint": hint_edit.text.strip_edges(),
		"par_time": par_spin.value,
	}, true)
	if challenge_check.button_pressed:
		out.challenge = true
	else:
		out.erase("challenge")
	return out


func _confirm() -> void:
	var id: String = meta().id
	var valid := RegEx.create_from_string("^[a-z0-9_]+$")
	if valid.search(id) == null:
		message.text = Lang.t("Identifiant : des minuscules sans accent, des chiffres ou _.")
		return
	save_confirmed.emit(meta())


func _open(index: int) -> void:
	hide()
	opened.emit(_paths[index])
