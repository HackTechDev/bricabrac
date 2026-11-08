class_name Tutorial
extends Control
## Tutoriel intégré : une bulle guide le joueur pas à pas et entoure l'élément à utiliser.
## Chaque étape avance seule dès que sa condition est remplie, quel que soit l'ordre des gestes :
## une étape déjà faite (machine restaurée, pièce posée en avance) est simplement sautée.
##
## Une étape : {"text", "until", "target", "zone", "running_text", "retry"}.
## `until` vaut "ack" pour une étape d'explication, validée par le bouton Compris.

signal finished(skipped: bool)

const BUBBLE_WIDTH := 330.0
const MARGIN := 8.0
const GAP := 18.0
const HIGHLIGHT := Color("ffc94d")

## Évalue une condition d'étape, par exemple "placed:plank" (fournie par l'interface).
var condition: Callable
## Rectangle à l'écran d'une cible, par exemple "bin:plank" ; vide si introuvable.
var locate: Callable
## Rectangles à l'écran que la bulle devrait éviter de cacher : pièces, bac, boutons.
var obstacles: Callable
var steps: Array = []
var index := -1

var _bubble: PanelContainer
var _counter: Label
var _text: Label
var _ok_button: Button
var _skip_button: Button
var _retry := false
var _was_running := false
var _time := 0.0
var _placed_for := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_bubble()
	hide()


func start(p_steps: Array) -> void:
	steps = p_steps
	index = 0
	_retry = false
	_placed_for = ""
	_was_running = condition.call("running")
	show()
	if not _advance():
		_show_step()


func stop() -> void:
	index = -1
	hide()


func is_active() -> bool:
	return visible and index >= 0 and index < steps.size()


func current_text() -> String:
	return _text.text


func bubble_rect() -> Rect2:
	return _bubble.get_global_rect()


func target_rect() -> Rect2:
	return locate.call(steps[index].get("target", "")) if is_active() else Rect2()


func _process(delta: float) -> void:
	if not is_active():
		return
	_time += delta
	var running: bool = condition.call("running")
	if _advance():
		return
	if _was_running and not running and steps[index].has("retry"):
		_retry = true
	_was_running = running
	_show_step()


## Passe les étapes remplies ; renvoie true si le tutoriel vient de se terminer.
func _advance() -> bool:
	while index < steps.size() and _met(steps[index]):
		index += 1
		_retry = false
	if index >= steps.size():
		stop()
		finished.emit(false)
		return true
	return false


func _met(step: Dictionary) -> bool:
	var until: String = step.get("until", "ack")
	return until != "ack" and condition.call(until)


func _show_step() -> void:
	var step: Dictionary = steps[index]
	var text: String = step.text
	if condition.call("running") and step.has("running_text"):
		text = step.running_text
	elif _retry:
		text = step.retry
	_text.text = Lang.t(text)
	_counter.text = Lang.t("Tutoriel  %d / %d") % [index + 1, steps.size()]
	_ok_button.visible = step.get("until", "ack") == "ack"
	# La bulle ne se replace qu'au changement d'étape ou de texte, jamais pendant la simulation.
	var key := "%d|%s" % [index, text]
	if key != _placed_for:
		_placed_for = key
		_bubble.reset_size()
		_bubble.position = _bubble_position(target_rect(), locate.call(step.get("zone", "")),
				_bubble.size)
	queue_redraw()


## Choisit, parmi plusieurs places autour de la cible, celle qui cache le moins de choses tout en
## restant proche. La cible et la zone indiquée ne sont jamais couvertes.
func _bubble_position(target: Rect2, zone: Rect2, bubble: Vector2) -> Vector2:
	var screen := get_viewport_rect().size
	var lowest := Vector2(MARGIN, 60.0)
	var highest := screen - bubble - Vector2(MARGIN, MARGIN)
	var anchor := target.get_center() if target.has_area() else Vector2(520.0, 360.0)
	var candidates: Array[Vector2] = [
		Vector2(520.0, 360.0) - bubble / 2.0,
		Vector2(lowest.x, lowest.y), Vector2(1030.0 - bubble.x, lowest.y),
		Vector2(lowest.x, 640.0 - bubble.y), Vector2(1030.0 - bubble.x, 640.0 - bubble.y),
	]
	if target.has_area():
		for y: float in [target.get_center().y - bubble.y / 2.0, target.position.y, target.end.y - bubble.y]:
			candidates.append(Vector2(target.position.x - bubble.x - GAP, y))
			candidates.append(Vector2(target.end.x + GAP, y))
		for x: float in [target.position.x, target.end.x - bubble.x, target.get_center().x - bubble.x / 2.0]:
			candidates.append(Vector2(x, target.end.y + GAP))
			candidates.append(Vector2(x, target.position.y - bubble.y - GAP))
	var avoid: Array = obstacles.call() if obstacles.is_valid() else []
	var best := candidates[0].clamp(lowest, highest)
	var best_cost := INF
	for candidate in candidates:
		var rect := Rect2(candidate.clamp(lowest, highest), bubble)
		if rect.intersects(target.grow(6.0)) or rect.intersects(zone):
			continue
		# Cacher une pièce coûte bien plus cher que s'éloigner de la cible.
		var cost := rect.get_center().distance_to(anchor)
		for obstacle: Rect2 in avoid:
			cost += rect.intersection(obstacle).get_area() * 10.0
		if cost < best_cost:
			best_cost = cost
			best = rect.position
	return best


func _draw() -> void:
	if not is_active():
		return
	var pulse := 1.0 if Accessibility.reduce_motion else 0.55 + 0.45 * sin(_time * 5.0)
	var bubble := bubble_rect()
	var step: Dictionary = steps[index]
	var zone: Rect2 = locate.call(step.get("zone", ""))
	if zone.has_area():
		draw_rect(zone, Color(HIGHLIGHT, 0.1))
		_dashed_rect(zone, Color(HIGHLIGHT, 0.4 + 0.4 * pulse))
	var target := target_rect()
	if target.has_area():
		var ring := target.grow(5.0)
		draw_rect(ring, Color(HIGHLIGHT, pulse), false, 3.0)
		var from := _closest_on_rect(bubble, ring.get_center())
		var to := _closest_on_rect(ring, bubble.get_center())
		draw_line(from, to, Color(HIGHLIGHT, 0.8), 2.0)
		draw_circle(to, 4.0, HIGHLIGHT)


func _dashed_rect(r: Rect2, col: Color) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], col, 2.0, 8.0)


func _closest_on_rect(r: Rect2, p: Vector2) -> Vector2:
	return p.clamp(r.position, r.end)


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4ecd8")
	style.border_color = HIGHLIGHT
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12.0)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	_bubble.add_theme_stylebox_override("panel", style)
	_bubble.custom_minimum_size.x = BUBBLE_WIDTH
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bubble)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_bubble.add_child(col)
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", 12)
	_counter.add_theme_color_override("font_color", Color("8a6d2c"))
	col.add_child(_counter)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = BUBBLE_WIDTH - 24.0
	_text.add_theme_color_override("font_color", Color("1d2b45"))
	col.add_child(_text)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	_skip_button = Button.new()
	_skip_button.text = Lang.t("Passer le tutoriel")
	_skip_button.flat = true
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_color_override("font_color", Color("6b7280"))
	_skip_button.add_theme_color_override("font_hover_color", Color("1d2b45"))
	_skip_button.pressed.connect(func() -> void:
		stop()
		finished.emit(true))
	row.add_child(_skip_button)
	_ok_button = Button.new()
	_ok_button.text = Lang.t("Compris")
	_ok_button.focus_mode = Control.FOCUS_NONE
	_ok_button.pressed.connect(func() -> void:
		index += 1
		_retry = false
		if not _advance():
			_show_step())
	row.add_child(_ok_button)
