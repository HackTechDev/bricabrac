class_name TitleScreen
extends Control
## Écran titre : le nom du jeu au-dessus d'une petite machine animée (engrenages, tapis, bille
## qui roule), la progression du joueur et les portes d'entrée du jeu.
## Entrée ou Espace : jouer ; il se referme en fondu.

signal play
signal choose
signal sandbox
signal editor
signal gallery
signal options
## Le joueur veut quitter : le jeu demande confirmation.
signal quit_requested

const BG := Color("14203a")
const FADE := 0.3

var progress_text := ""
var resume := false

var _time := 0.0
var _play_button: Button
var _progress: Label
var _buttons: VBoxContainer
var _tween: Tween


func _init() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)  # Taille fixe de la fenêtre du jeu.
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 60  # Au-dessus des marques d'objectif et de l'aperçu de corde du plateau.
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.custom_minimum_size.x = 300
	_buttons.position = Vector2(490, 292)
	_buttons.size = Vector2(300, 0)
	add_child(_buttons)
	_play_button = _add_button(Lang.t("Jouer"), play)
	_add_button(Lang.t("Choisir un niveau"), choose)
	_add_button(Lang.t("Bac à sable"), sandbox)
	_add_button(Lang.t("Galerie des joueurs"), gallery)
	_add_button(Lang.t("Éditeur de niveaux"), editor)
	_add_button(Lang.t("Options"), options, false)
	if not OS.has_feature("web"):
		var quit := Button.new()
		quit.text = Lang.t("Quitter")
		quit.focus_mode = Control.FOCUS_NONE
		quit.custom_minimum_size.y = 40
		quit.pressed.connect(func() -> void: quit_requested.emit())
		_buttons.add_child(quit)
	_progress = Label.new()
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.position = Vector2(340, 664)
	_progress.size = Vector2(600, 24)
	_progress.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(_progress)


## `closing` : l'écran se referme avant d'émettre le signal (les options s'ouvrent par-dessus).
func _add_button(text: String, sig: Signal, closing := true) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 40
	button.pressed.connect(func() -> void:
		if closing:
			close()
		sig.emit())
	_buttons.add_child(button)
	return button


## Affiche l'écran ; `p_resume` : le joueur a déjà commencé, « Jouer » devient « Continuer ».
func open(p_progress: String, p_resume: bool) -> void:
	progress_text = p_progress
	resume = p_resume
	_play_button.text = Lang.t("Continuer") if resume else Lang.t("Jouer")
	_progress.text = progress_text
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()


## Fondu de sortie ; l'écran ne bloque plus la souris dès le début du fondu.
func close() -> void:
	if not visible:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE)
	_tween.tween_callback(hide)


func is_open() -> bool:
	return visible and mouse_filter == Control.MOUSE_FILTER_STOP


func play_button() -> Button:
	return _play_button


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_open():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		close()
		play.emit()


func _process(delta: float) -> void:
	if visible and not Accessibility.reduce_motion:
		_time += delta
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var grid := Color(1, 1, 1, 0.04)
	for x in range(0, 1281, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), grid)
	for y in range(0, 721, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), grid)
	_draw_machine()
	var font := get_theme_default_font()
	var title := "Bric-à-Brac"
	var title_size := 84
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var at := Vector2((1280.0 - width) / 2.0, 210)
	draw_string(font, at + Vector2(4, 5), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Part.INK)
	draw_string(font, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Part.GOLD)
	var tagline := Lang.t("Des machines farfelues, une pièce à la fois")
	var tag_width := font.get_string_size(tagline, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2((1280.0 - tag_width) / 2.0, 262), tagline, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 1, 1, 0.75))


## Décor animé : deux engrenages qui s'entraînent, un tapis et une bille qui le parcourt.
func _draw_machine() -> void:
	var t := _time
	_draw_gear(Vector2(170, 520), 70.0, 14, t * 0.8, Part.STEEL)
	_draw_gear(Vector2(276, 452), 45.0, 9, -t * 0.8 * 14.0 / 9.0 + 0.17, Part.WOOD)
	_draw_gear(Vector2(1120, 170), 56.0, 11, -t * 0.5, Part.STEEL)
	# Tapis roulant en bas à droite, chevrons qui défilent.
	var belt := Rect2(860, 600, 340, 22)
	draw_rect(belt, Color("2b3a55"))
	draw_rect(belt, Part.INK, false, 2.0)
	var shift := fposmod(t * 60.0, 30.0)
	for i in 12:
		var x := belt.position.x + 8.0 + i * 30.0 + shift
		if x < belt.end.x - 10.0:
			draw_polyline(PackedVector2Array([Vector2(x, 605), Vector2(x + 7, 611), Vector2(x, 617)]),
					Color(1, 1, 1, 0.5), 2.0)
	# Bille qui roule sur le tapis, tombe, et recommence.
	var cycle := fposmod(t, 4.0)
	var ball := Vector2(870.0 + cycle * 90.0, 588.0)
	if ball.x > 1200.0:
		var fall := (ball.x - 1200.0) / 90.0
		ball = Vector2(1200.0 + fall * 40.0, 588.0 + 490.0 * fall * fall)
	draw_circle(ball, 12.0, Color("4aa3ff"))
	draw_arc(ball, 12.0, 0.0, TAU, 24, Part.INK, 2.0)
	var spin := Vector2.from_angle(cycle * 7.5) * 7.0
	draw_line(ball - spin, ball + spin, Part.INK, 2.0)
	# Lampe qui clignote au rythme de la bille.
	var lamp := Vector2(120, 170)
	var lit := cycle > 3.0
	draw_circle(lamp, 26.0, Color(Part.GOLD, 0.25) if lit else Color(0, 0, 0, 0))
	draw_circle(lamp, 16.0, Part.GOLD if lit else Color("4a5670"))
	draw_arc(lamp, 16.0, 0.0, TAU, 24, Part.INK, 2.0)
	draw_rect(Rect2(lamp + Vector2(-10, 16), Vector2(20, 12)), Part.STEEL)


func _draw_gear(center: Vector2, radius: float, teeth: int, angle: float, col: Color) -> void:
	var outline := PackedVector2Array()
	for i in teeth * 4:
		var a := angle + i * TAU / (teeth * 4)
		var r := radius if i % 4 < 2 else radius - 10.0
		outline.append(center + Vector2.from_angle(a) * r)
	draw_colored_polygon(outline, Color(col, 0.35))
	outline.append(outline[0])
	draw_polyline(outline, Color(col, 0.8), 2.0)
	draw_circle(center, radius * 0.25, Color(col, 0.5))
	for i in 3:
		var a := angle + i * TAU / 3.0
		draw_line(center, center + Vector2.from_angle(a) * (radius - 14.0), Color(col, 0.6), 3.0)
