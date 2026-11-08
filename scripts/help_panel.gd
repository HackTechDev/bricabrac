class_name HelpPanel
extends Control
## Page d'aide, ouverte par « Aide » sur l'écran titre ou F1 : l'essentiel des commandes, puis
## l'origine du jeu, son développeur et le lien vers son code. Échap ou « Fermer » la referment.

const REPO_URL := "https://github.com/HackTechDev/bricabrac"
const DEVELOPER := "Le Sanglier des Ardennes"

var link: LinkButton
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
	panel.custom_minimum_size = Vector2(640, 0)
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = Lang.t("Aide")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Part.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_paragraph(box, Lang.t("Bric-à-Brac est un jeu de machines farfelues : pose des pièces dans l'atelier, lance la machine, et la réaction en chaîne doit atteindre l'objectif du niveau."))

	_heading(box, Lang.t("L'essentiel"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for row: Array in [
		[Lang.t("Glisser depuis le bac"), Lang.t("poser une pièce")],
		[Lang.t("R ou molette, F, C"), Lang.t("pivoter, retourner, changer de canal")],
		[Lang.t("Clic droit"), Lang.t("menu de la pièce")],
		[Lang.t("Espace"), Lang.t("lancer ou arrêter la machine")],
		[Lang.t("Ctrl+Z, Ctrl+Y"), Lang.t("annuler, rétablir")],
		[Lang.t("T"), Lang.t("trace du dernier essai")],
		[Lang.t("Tab, O, Échap"), Lang.t("choisir un niveau, options, écran titre")],
		[Lang.t("F1"), Lang.t("cette page")],
	]:
		var key := Label.new()
		key.text = row[0]
		key.add_theme_color_override("font_color", Part.GOLD)
		grid.add_child(key)
		var what := Label.new()
		what.text = row[1]
		grid.add_child(what)
	_paragraph(box, Lang.t("Bloqué ? Le bouton Indice, en haut de l'écran, aide en trois paliers. Le tutoriel complet est dans le fichier TUTORIAL.md du projet."))

	_heading(box, Lang.t("À propos"))
	_paragraph(box, Lang.t("Ce jeu a été vibe-codé avec Claude, l'assistant d'IA d'Anthropic : le code, les niveaux, les sons et la musique ont été écrits en conversation avec lui."))
	_paragraph(box, Lang.t("Développeur : %s") % DEVELOPER)
	var row := HBoxContainer.new()
	box.add_child(row)
	var source := Label.new()
	source.text = Lang.t("Code source (licence MIT) :")
	row.add_child(source)
	link = LinkButton.new()
	link.text = REPO_URL
	link.uri = REPO_URL
	link.focus_mode = Control.FOCUS_NONE
	link.add_theme_color_override("font_color", Color("8cc8ff"))
	row.add_child(link)

	_close = Button.new()
	_close.text = Lang.t("Fermer")
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size.y = 36
	_close.pressed.connect(close)
	box.add_child(_close)
	panel.resized.connect(func() -> void: panel.position = (size - panel.size) / 2.0)
	hide()


func open() -> void:
	show()


func close() -> void:
	hide()


func _heading(box: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	box.add_child(label)


func _paragraph(box: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 600
	box.add_child(label)


## Tant qu'elle est ouverte, la page garde le clavier : Échap ou F1 la ferment.
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if event.pressed and event.keycode in [KEY_ESCAPE, KEY_F1]:
		close()
