class_name LevelEditor
extends VBoxContainer
## Éditeur de niveaux : panneau affiché sous le bac quand le plan de travail de l'éditeur est
## ouvert. Le plateau sert de plan de travail (tout ce qu'on y pose devient le décor) ; ce panneau
## règle le reste : nom, texte de l'objectif, pièce objectif, inventaire du joueur.
## La logique de partie reste dans main.gd, qui appelle `build_level` pour essayer ou enregistrer.

signal try_requested
signal save_requested
signal delete_requested
signal reset_requested
signal share_requested

## Identifiant du niveau personnel en cours d'édition ; vide pour un nouveau niveau.
var custom_id := ""
## Pièces offertes au joueur : genre → nombre.
var inventory := {}
## Preuve que l'auteur a résolu le niveau : {"signature": empreinte, "solution": disposition}.
var proof := {}

var name_edit: LineEdit
var goal_edit: LineEdit
var goal_button: Button
var inventory_button: Button
var delete_button: Button
var proof_label: Label
var _dialog: PopupPanel
var _spins := {}


func _init() -> void:
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Éditeur de niveaux"
	title.add_theme_color_override("font_color", Part.GOLD)
	add_child(title)
	name_edit = _line("Nom du niveau")
	goal_edit = _line("Objectif affiché au joueur")
	proof_label = Label.new()
	proof_label.add_theme_font_size_override("font_size", 13)
	proof_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(proof_label)
	var grid := GridContainer.new()
	grid.columns = 2
	add_child(grid)
	goal_button = _button(grid, "Objectif (G)", "Fait de la pièce sélectionnée l'objectif du niveau, ou le lui retire.")
	inventory_button = _button(grid, "Inventaire…", "Pièces offertes au joueur.")
	var try_button := _button(grid, "Essayer", "Joue ton niveau avec l'inventaire choisi.")
	try_button.pressed.connect(func() -> void: try_requested.emit())
	var save_button := _button(grid, "Enregistrer", "Range le niveau dans « Mes niveaux ».")
	save_button.pressed.connect(func() -> void: save_requested.emit())
	var new_button := _button(grid, "Nouveau", "Vide le plan de travail pour un autre niveau.")
	new_button.pressed.connect(func() -> void: reset_requested.emit())
	delete_button = _button(grid, "Supprimer", "Supprime ce niveau de « Mes niveaux ».")
	delete_button.pressed.connect(func() -> void: delete_requested.emit())
	var share_button := _button(self, "Partager le niveau…", "Code ou fichier à donner à d'autres joueurs. Le niveau doit être résolu.")
	share_button.pressed.connect(func() -> void: share_requested.emit())
	inventory_button.pressed.connect(open_inventory)
	_build_dialog()


func _line(placeholder: String) -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.max_length = 60
	add_child(line)
	return line


func _button(parent: Control, text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


## Remet l'éditeur à zéro, ou le prépare pour modifier un niveau personnel existant.
func load_from(level: Dictionary) -> void:
	custom_id = level.get("id", "")
	name_edit.text = level.get("name", "")
	goal_edit.text = level.get("goal_text", "")
	inventory = level.get("inventory", {}).duplicate()
	proof = level.get("proof", {}).duplicate(true)
	if level.get("verified", false):
		proof = {"signature": LevelData.signature(level), "solution": level.get("solution", [])}
	delete_button.disabled = custom_id == ""
	_sync_spins()


## Le niveau `level`, tel qu'il est sur le plan de travail, a-t-il été résolu par l'auteur ?
func is_proven(level: Dictionary) -> bool:
	return not proof.is_empty() and proof.signature == LevelData.signature(level)


func show_proof(level: Dictionary) -> void:
	if is_proven(level):
		proof_label.text = "✔ Résolu par toi : prêt à partager."
		proof_label.add_theme_color_override("font_color", Color("8fd18f"))
	else:
		proof_label.text = "✘ Pas encore résolu : gagne-le avec « Essayer » avant de le partager."
		proof_label.add_theme_color_override("font_color", Color("f0a070"))


func inventory_text() -> String:
	var total := 0
	for count: int in inventory.values():
		total += count
	return "Inventaire (%d)…" % total


func refresh() -> void:
	inventory_button.text = inventory_text()
	delete_button.disabled = custom_id == ""


func open_inventory() -> void:
	_sync_spins()
	_dialog.popup_centered(Vector2i(520, 560))


func _build_dialog() -> void:
	_dialog = PopupPanel.new()
	add_child(_dialog)
	var col := VBoxContainer.new()
	_dialog.add_child(col)
	var head := Label.new()
	head.text = "Pièces offertes au joueur"
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 480)
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	scroll.add_child(grid)
	for kind: String in Catalog.INFO:
		var label := Label.new()
		label.text = Catalog.INFO[kind].label
		label.custom_minimum_size.x = 130
		grid.add_child(label)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 9
		spin.value_changed.connect(func(value: float) -> void:
			inventory[kind] = int(value)
			if int(value) == 0:
				inventory.erase(kind)
			refresh())
		grid.add_child(spin)
		_spins[kind] = spin
	var close := Button.new()
	close.text = "Fermer"
	close.pressed.connect(_dialog.hide)
	col.add_child(close)


func _sync_spins() -> void:
	for kind: String in _spins:
		(_spins[kind] as SpinBox).set_value_no_signal(inventory.get(kind, 0))
	refresh()
