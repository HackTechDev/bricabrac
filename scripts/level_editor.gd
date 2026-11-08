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
signal open_official_requested
signal save_official_requested
signal physics_changed(gravity: float, wind: Vector2)

## Directions du vent proposées, dans l'ordre de la liste : aucun, puis les huit directions.
const WIND_DIRECTIONS: Array[String] = ["Aucun vent", "→ vers la droite", "↘", "↓ vers le bas", "↙",
		"← vers la gauche", "↖", "↑ vers le haut", "↗"]

## Identifiant du niveau personnel en cours d'édition ; vide pour un nouveau niveau.
var custom_id := ""
## Pièces offertes au joueur : genre → nombre.
var inventory := {}
## Preuve que l'auteur a résolu le niveau : {"signature": empreinte, "solution": disposition}.
var proof := {}
## Niveau du jeu ouvert depuis `levels/` : {"path": fichier, "meta": fiche (id, monde, textes…)}.
var source := {}
var official_box: HBoxContainer

var name_edit: LineEdit
var goal_edit: LineEdit
var goal_button: Button
var inventory_button: Button
var delete_button: Button
var proof_label: Label
var physics_button: Button
var gravity_slider: HSlider
var wind_direction: OptionButton
var wind_force: SpinBox
var _dialog: PopupPanel
var _physics_dialog: PopupPanel
var _gravity_label: Label
var _spins := {}


func _init() -> void:
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Éditeur de niveaux"
	title.add_theme_color_override("font_color", Part.GOLD)
	add_child(title)
	name_edit = _line("Nom du niveau")
	goal_edit = _line("Objectif affiché au joueur")
	goal_edit.max_length = 160  # Les objectifs des niveaux du jeu dépassent parfois 60 signes.
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
	physics_button = _button(self, "Physique…", "Gravité et vent du niveau.")
	physics_button.pressed.connect(open_physics)
	var share_button := _button(self, "Partager le niveau…", "Code ou fichier à donner à d'autres joueurs. Le niveau doit être résolu.")
	share_button.pressed.connect(func() -> void: share_requested.emit())
	official_box = HBoxContainer.new()
	add_child(official_box)
	var open_official := _button(official_box, "Ouvrir (jeu)…", "Ouvre un niveau du jeu, du dossier levels/.")
	open_official.pressed.connect(func() -> void: open_official_requested.emit())
	var save_official := _button(official_box, "Écrire (jeu)…", "Enregistre ce niveau dans levels/, avec sa solution vérifiée.")
	save_official.pressed.connect(func() -> void: save_official_requested.emit())
	official_box.visible = false
	inventory_button.pressed.connect(open_inventory)
	_build_dialog()
	_build_physics_dialog()


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
	# Le panneau est étroit : un libellé trop long s'abrège au lieu de l'élargir.
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(b)
	return b


## Remet l'éditeur à zéro, ou le prépare pour modifier un niveau personnel existant.
func load_from(level: Dictionary) -> void:
	source = {}
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


# --- Physique du niveau -------------------------------------------------------------

## Affiche la gravité et le vent du plan de travail, sans renvoyer de signal.
func show_physics(gravity: float, wind: Vector2) -> void:
	gravity_slider.set_value_no_signal(gravity)
	_gravity_label.text = "Gravité : ×%s" % String.num(gravity, 1).replace(".", ",")
	var direction := 0
	if wind != Vector2.ZERO:
		direction = 1 + wrapi(roundi(wind.angle() / (PI / 4.0)), 0, 8)
		wind_force.set_value_no_signal(wind.length())
	wind_direction.select(direction)
	wind_force.editable = direction != 0
	var text := "×%s" % String.num(gravity, 1).replace(".", ",")
	text += ", sans vent" if wind == Vector2.ZERO else ", vent %s %d" % [
			WIND_DIRECTIONS[direction].get_slice(" ", 0), roundi(wind.length())]
	physics_button.text = "Physique : " + text
	physics_button.tooltip_text = "Gravité et vent du niveau : gravité %s." % text


func open_physics() -> void:
	_physics_dialog.popup_centered()


## Vent choisi dans la fenêtre : direction et force.
func chosen_wind() -> Vector2:
	if wind_direction.selected <= 0:
		return Vector2.ZERO
	var angle := (wind_direction.selected - 1) * PI / 4.0
	return (Vector2.from_angle(angle) * wind_force.value).round()


func _build_physics_dialog() -> void:
	_physics_dialog = PopupPanel.new()
	add_child(_physics_dialog)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(400, 0)
	_physics_dialog.add_child(col)
	var head := Label.new()
	head.text = "Physique du niveau"
	head.add_theme_color_override("font_color", Part.GOLD)
	col.add_child(head)
	_gravity_label = Label.new()
	col.add_child(_gravity_label)
	gravity_slider = HSlider.new()
	gravity_slider.min_value = 0.1
	gravity_slider.max_value = 2.0
	gravity_slider.step = 0.1
	gravity_slider.value = 1.0
	gravity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gravity_slider.value_changed.connect(func(_v: float) -> void: _emit_physics())
	col.add_child(gravity_slider)
	var row := HBoxContainer.new()
	col.add_child(row)
	wind_direction = OptionButton.new()
	for text in WIND_DIRECTIONS:
		wind_direction.add_item(text)
	wind_direction.item_selected.connect(func(_i: int) -> void: _emit_physics())
	wind_direction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(wind_direction)
	var force := Label.new()
	force.text = "Force"
	row.add_child(force)
	wind_force = SpinBox.new()
	wind_force.min_value = 30.0
	wind_force.max_value = 300.0
	wind_force.step = 30.0
	wind_force.value = 120.0
	wind_force.custom_minimum_size.x = 110
	wind_force.value_changed.connect(func(_v: float) -> void: _emit_physics())
	row.add_child(wind_force)
	var note := Label.new()
	note.text = "Un vent de 120 emporte un ballon ; le boulet y résiste."
	note.add_theme_font_size_override("font_size", 13)
	col.add_child(note)
	var close := Button.new()
	close.text = "Fermer"
	close.pressed.connect(_physics_dialog.hide)
	col.add_child(close)


func _emit_physics() -> void:
	physics_changed.emit(snappedf(gravity_slider.value, 0.1), chosen_wind())
