class_name Chrono
extends Control
## Chronomètre de la barre du haut : temps de simulation, avec un cadran qui fait un tour en
## 10 secondes. L'arc doré marque le temps à battre pour l'objectif « Rapide » ; le temps reste
## doré tant qu'il est tenu, et passe au vert à la victoire. Sous le temps, en petit, le nombre
## d'essais du niveau.

const TURN := 10.0
const GOLD := Color("ffcf5c")
const WIN := Color("8fe388")
const IDLE := Color(1, 1, 1, 0.55)
const TRIES_SIZE := 12

enum State { IDLE, RUNNING, WON }

var seconds := 0.0
## Temps de l'objectif « Rapide » ; 0 : pas d'objectif de temps.
var par := 0.0
var state := State.IDLE
## Nombre d'essais affiché sous le temps ; vide pour le masquer.
var tries := ""


func _init() -> void:
	custom_minimum_size = Vector2(104, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS


## Réinitialise pour un nouveau niveau.
func reset(p_par: float) -> void:
	par = p_par
	seconds = 0.0
	state = State.IDLE
	tooltip_text = Lang.t("Chronomètre : durée de la simulation.")
	if par > 0.0:
		tooltip_text += Lang.t("\nObjectif Rapide : moins de %s s.") % _num(par)
	tooltip_text += Lang.t("\nEn dessous : nombre de lancements de la machine dans ce niveau.")
	queue_redraw()


func set_tries(text: String) -> void:
	if text != tries:
		tries = text
		queue_redraw()


## Suit la simulation ; à l'arrêt, garde le dernier temps affiché.
func track(running: bool, won: bool, elapsed: float) -> void:
	var next := State.IDLE
	if running:
		next = State.WON if won else State.RUNNING
		if elapsed != seconds:
			seconds = elapsed
			queue_redraw()
	if next != state:
		state = next
		queue_redraw()


func text() -> String:
	return Lang.t("%s s") % _num(seconds)


func color() -> Color:
	match state:
		State.WON:
			return WIN
		State.RUNNING:
			return GOLD if par > 0.0 and seconds <= par else Color.WHITE
	return IDLE


func _draw() -> void:
	var center := Vector2(16, size.y / 2.0)
	var col := color()
	var r := 11.0
	if par > 0.0:
		var span := minf(par / TURN, 1.0) * TAU
		draw_arc(center, r - 3.0, -PI / 2.0, -PI / 2.0 + span, 24, Color(GOLD, 0.6), 3.0)
	draw_arc(center, r, 0.0, TAU, 32, col, 2.0)
	draw_rect(Rect2(center + Vector2(-3, -r - 5), Vector2(6, 3)), col)
	var hand := Vector2.from_angle(-PI / 2.0 + fposmod(seconds, TURN) / TURN * TAU) * (r - 2.0)
	draw_line(center, center + hand, col, 2.0)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	if tries != "":
		baseline -= 8.0
		draw_string(font, Vector2(34, baseline + 17.0), tries, HORIZONTAL_ALIGNMENT_LEFT, -1,
				TRIES_SIZE, Color(1, 1, 1, 0.6))
	draw_string(font, Vector2(34, baseline), text(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


static func _num(value: float) -> String:
	return ("%.1f" % value).replace(".", Lang.decimal_mark())
