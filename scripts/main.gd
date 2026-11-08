extends Control
## Interface : barre du haut, bac à pièces, glisser-déposer et écran de victoire.
## Toute la mécanique de jeu vit dans Board.

const TOP_H := 56.0
const PANEL_X := 1040.0
const BIN_ORDER: Array[String] = [
	"plank", "domino", "spring", "seesaw", "conveyor", "fan", "plate", "switch", "timer", "trapdoor", "door", "scissors", "magnet", "motor", "gear", "portal", "water",
	"cannon",
	"pulley", "rope", "ball", "ball_bouncy", "ball_heavy", "crate", "balloon", "spikes",
]

var save_path := "user://progress.cfg"
var board: Board
var levels: Array = []
var current := 0
var completed := {}
## Objectifs bonus obtenus, par niveau : identifiant → liste de types (voir Bonus).
var bonuses := {}

var selected: Part
var drag_part: Part
var drag_is_new := false
var drag_origin := Vector2.ZERO

var rope_tool := false
var rope_from: Part
var rope_from_off := Vector2.ZERO
var rope_via: Array = []
var muted := false

var histories := {}
var saved_layouts := {}
## Tutoriels terminés ou passés : ils ne se relancent plus d'eux-mêmes (le bouton Indice, si).
var tutorials_done := {}
var show_tutorials := true
var tutorial: Tutorial

var _level_picker: OptionButton
var _run_button: Button
var _clear_button: Button
var _goal_label: Label
var _status: Label
var _bin: VBoxContainer
var _items: Array[BinItem] = []
var _ctx_buttons := {}
var _win_overlay: Control
var _win_bonus: Label
var _win_next: Button
var _rope_preview: Line2D
var _sound_button: Button
var _mouse := Vector2.ZERO
var _tooltip: PanelContainer
var _tooltip_label: Label
var _hovered: Part
var _hover_time := 0.0


func _ready() -> void:
	levels = LevelData.all()
	_load_progress()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()

	board = Board.new()
	board.position = Vector2(0, TOP_H)
	add_child(board)
	board.won.connect(_on_won)
	board.inventory_changed.connect(_refresh_bin)
	_rope_preview = Line2D.new()
	_rope_preview.width = 2.5
	_rope_preview.default_color = Color(RopePart.COLOR, 0.8)
	_rope_preview.z_index = 10
	board.add_child(_rope_preview)

	_build_top_bar()
	_build_side_panel()
	_build_status_bar()
	_build_tooltip()
	tutorial = Tutorial.new()
	tutorial.condition = _tutorial_condition
	tutorial.locate = _tutorial_target
	tutorial.obstacles = _tutorial_obstacles
	tutorial.finished.connect(_on_tutorial_finished)
	add_child(tutorial)
	_build_win_overlay()
	load_level(_first_unsolved())


## Rappel des conditions inhabituelles du niveau, à la suite de l'objectif.
static func _physics_note(level: Dictionary) -> String:
	var notes: PackedStringArray = []
	var g: float = level.get("gravity", 1.0)
	if g < 1.0:
		notes.append("gravité faible (×%s)" % String.num(g, 2).replace(".", ","))
	elif g > 1.0:
		notes.append("gravité forte (×%s)" % String.num(g, 2).replace(".", ","))
	var w: Vector2 = level.get("wind", Vector2.ZERO)
	if w != Vector2.ZERO:
		var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
		notes.append("vent %s" % arrows[wrapi(roundi(w.angle() / (PI / 4.0)), 0, 8)])
	return "" if notes.is_empty() else "  —  " + ", ".join(notes)


func load_level(index: int) -> void:
	_stop_drag()
	_hide_tooltip()
	_cancel_rope()
	current = index
	_select(null)
	_win_overlay.hide()
	board.load_level(levels[index])
	var level_id: String = levels[index].id
	var dropped := board.restore_layout(saved_layouts.get(level_id, []))
	if not histories.has(level_id):
		histories[level_id] = History.new(board.layout())
	_goal_label.text = levels[index].goal_text + _physics_note(levels[index])
	_status.text = levels[index].get("intro", "")
	if not board.placed.is_empty():
		_status.text = "Ta machine a été remise en place. Ctrl+Z annule ta dernière action."
	if dropped > 0:
		_status.text = "%d pièce(s) sauvegardée(s) ne sont plus valides dans ce niveau." % dropped
	_rebuild_bin()
	_refresh_level_picker()
	_refresh_controls()
	tutorial.stop()
	if show_tutorials and levels[index].has("tutorial") and not completed.has(level_id) \
			and not tutorials_done.has(level_id):
		_start_tutorial.call_deferred()


func toggle_run() -> void:
	_stop_drag()
	_cancel_rope()
	_select(null)
	_win_overlay.hide()
	board.sfx.play("stop" if board.running else "start")
	if board.running:
		board.stop()
	else:
		board.start()
	_refresh_bin()
	_refresh_controls()


# --- Saisie ---------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse = _to_board(event.position)
		_update_rope_preview()
		_track_hover(event)
	if drag_part == null:
		return
	if event is InputEventMouseMotion:
		_drag_to(_mouse)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_drop()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_click(event.button_index)


func _handle_key(event: InputEventKey) -> void:
	if event.is_command_or_control_pressed():
		match event.keycode:
			KEY_Z:
				_redo() if event.shift_pressed else _undo()
			KEY_Y:
				_redo()
		return
	match event.keycode:
		KEY_SPACE:
			toggle_run()
		KEY_M:
			_toggle_sound()
		KEY_ESCAPE:
			if rope_tool:
				_cancel_rope()
				_status.text = "Corde annulée."
		KEY_R:
			_rotate_selected(-1.0 if event.shift_pressed else 1.0)
		KEY_F:
			_flip_selected()
		KEY_C:
			_cycle_channel()
		KEY_DELETE, KEY_BACKSPACE:
			_remove_selected()


func _handle_click(button: MouseButton) -> void:
	if board.running:
		return
	if rope_tool:
		_handle_rope_click(button)
		return
	match button:
		MOUSE_BUTTON_WHEEL_UP:
			_rotate_selected(-1.0)
		MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_selected(1.0)
		MOUSE_BUTTON_RIGHT:
			var target := board.part_at(_mouse)
			if _is_player_part(target):
				_select(target)
				_remove_selected()
		MOUSE_BUTTON_LEFT:
			var target := board.part_at(_mouse)
			if _is_player_part(target):
				_select(target)
				if not target is RopePart:
					drag_part = target
					drag_is_new = false
					drag_origin = target.position
			else:
				_select(null)


func _to_board(screen_pos: Vector2) -> Vector2:
	return board.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _is_player_part(part: Part) -> bool:
	return part != null and board.placed.has(part.entry)


# --- Infobulles du plateau ------------------------------------------------------

const TOOLTIP_DELAY := 0.5


func _process(delta: float) -> void:
	if _hovered == null:
		return
	if not is_instance_valid(_hovered):
		_hide_tooltip()
		return
	_hover_time += delta
	if _hover_time >= TOOLTIP_DELAY and not _tooltip.visible:
		_show_tooltip()


## Un clic ou un glisser ferme l'infobulle ; survoler une autre pièce relance le délai.
func _track_hover(event: InputEventMouse) -> void:
	if event is InputEventMouseButton or drag_part != null:
		_hide_tooltip()
		return
	var inside := Rect2(Vector2.ZERO, Board.SIZE).has_point(_mouse)
	var part := board.part_at(_mouse) if inside else null
	if part != _hovered:
		_hide_tooltip()
		_hovered = part
	elif _tooltip.visible:
		_place_tooltip()


func _show_tooltip() -> void:
	var info: Dictionary = Catalog.INFO[_hovered.kind]
	var lines := PackedStringArray([info.label, info.desc])
	lines.append_array(_hovered.describe())
	if not _is_player_part(_hovered):
		lines.append("Pièce du décor : elle ne se déplace pas.")
	_tooltip_label.text = "\n".join(lines)
	_tooltip.reset_size()
	_tooltip.show()
	_place_tooltip()


func _place_tooltip() -> void:
	var at := board.to_global(_mouse) + Vector2(18, 18)
	var limit := get_viewport_rect().size - _tooltip.size - Vector2(4, 4)
	_tooltip.position = at.clamp(Vector2(4, 4), limit)


func _hide_tooltip() -> void:
	_hovered = null
	_hover_time = 0.0
	if _tooltip != null:
		_tooltip.hide()


func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f1a2e")
	style.border_color = Color("7f8fa6")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8.0)
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 20
	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_size_override("font_size", 13)
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)
	_tooltip.hide()


# --- Glisser-déposer ------------------------------------------------------------

func _grab_from_bin(kind: String) -> void:
	if board.running or board.remaining(kind) <= 0:
		return
	if kind == "rope":
		_select(null)
		rope_tool = true
		_status.text = "Corde : clique le premier objet à relier (Échap pour annuler)."
		return
	drag_part = board.place(kind, _mouse)
	drag_is_new = true
	_select(drag_part)
	_update_drag_tint()


func _drag_to(pos: Vector2) -> void:
	board.move_part(drag_part, pos)
	_update_drag_tint()


func _update_drag_tint() -> void:
	drag_part.modulate = Color.WHITE if board.is_valid(drag_part) else Color(1, 0.35, 0.35, 0.8)


func _drop() -> void:
	var part := drag_part
	drag_part = null
	part.modulate = Color.WHITE
	if board.is_valid(part):
		board.sfx.play("place")
		_commit()
		return
	board.sfx.play("deny")
	if drag_is_new:
		_select(null)
		board.remove(part)
		_status.text = "Pas de place ici : la pièce retourne dans le bac."
	else:
		board.move_part(part, drag_origin)
		_status.text = "Pas de place ici : la pièce reprend sa position."
	_commit()


func _stop_drag() -> void:
	if drag_part != null:
		_drop()


# --- Pose d'une corde -----------------------------------------------------------

func _handle_rope_click(button: MouseButton) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_cancel_rope()
		_status.text = "Corde annulée."
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	var target := board.part_at(_mouse)
	if target == null or target is RopePart:
		_status.text = "Clique sur une pièce."
		board.sfx.play("deny")
	elif rope_from == null:
		_start_rope(target)
	elif target is PulleyPart:
		_add_rope_pulley(target)
	else:
		_finish_rope(target)
	_update_rope_preview()


func _start_rope(target: Part) -> void:
	if not target.can_tie():
		_status.text = "Une corde commence sur un objet, pas sur une poulie."
		board.sfx.play("deny")
		return
	rope_from = target
	rope_from_off = target.rope_anchor(board.to_global(_mouse))
	board.sfx.play("tick")
	_status.text = "Corde : clique les poulies dans l'ordre, puis le second objet."


func _add_rope_pulley(target: Part) -> void:
	if rope_via.has(target.entry.id):
		_status.text = "La corde passe déjà par cette poulie."
		board.sfx.play("deny")
		return
	rope_via.append(target.entry.id)
	board.sfx.play("tick")


func _finish_rope(target: Part) -> void:
	if target == rope_from:
		_status.text = "Une corde relie deux pièces différentes."
		board.sfx.play("deny")
		return
	if not (rope_from.main_body is RigidBody2D or target.main_body is RigidBody2D):
		_status.text = "Une corde entre deux pièces fixes ne ferait rien : choisis un objet mobile."
		board.sfx.play("deny")
		return
	var off := target.rope_anchor(board.to_global(_mouse))
	board.add_rope(rope_from, rope_from_off, rope_via.duplicate(), target, off)
	board.sfx.play("place")
	_cancel_rope()
	_commit()
	_status.text = "Corde posée, tendue. Sélectionne-la et appuie sur R pour lui donner du mou."


func _cancel_rope() -> void:
	rope_tool = false
	rope_from = null
	rope_via.clear()
	_update_rope_preview()


func _update_rope_preview() -> void:
	if _rope_preview == null:
		return
	_rope_preview.clear_points()
	if rope_from == null:
		return
	_rope_preview.add_point(board.to_local(rope_from.main_body.to_global(rope_from_off)))
	for id: String in rope_via:
		_rope_preview.add_point(board.find_part(id).position)
	_rope_preview.add_point(_mouse)


# --- Annulation et sauvegarde des pièces ----------------------------------------

## À appeler à la fin de chaque action du joueur : une action égale une étape d'annulation.
func _commit() -> void:
	var state := board.layout()
	if _history().record(state):
		_store_layout(state)
	_refresh_context()


func _history() -> History:
	return histories.get(levels[current].id)


func _undo() -> void:
	if board.running or drag_part != null:
		return
	if rope_tool:
		_cancel_rope()
		_status.text = "Corde annulée."
	elif _history().can_undo():
		_show_state(_history().undo(), "Action annulée.")
	else:
		board.sfx.play("deny")


func _redo() -> void:
	if board.running or drag_part != null or rope_tool:
		return
	if _history().can_redo():
		_show_state(_history().redo(), "Action rétablie.")
	else:
		board.sfx.play("deny")


func _show_state(state: Array, message: String) -> void:
	_select(null)
	board.set_layout(state)
	_store_layout(state)
	board.sfx.play("tick")
	_status.text = message


func _store_layout(state: Array) -> void:
	saved_layouts[levels[current].id] = state
	_save_progress()


# --- Pièce sélectionnée ---------------------------------------------------------

func _select(part: Part) -> void:
	if is_instance_valid(selected):
		selected.selected = false
	selected = part
	if part != null:
		part.selected = true
	_refresh_context()


## Applique un changement ; pose interdite = retour à l'état précédent (sauf en plein glisser).
func _edit_selected(key: String, value: Variant) -> void:
	var old: Variant = selected.entry.get(key)
	selected.entry[key] = value
	var was_dragging := drag_part == selected
	var part := board.rebuild_part(selected)
	if not was_dragging and not board.is_valid(part):
		part.entry[key] = old
		part = board.rebuild_part(part)
		_status.text = "Pas assez de place pour cela."
		board.sfx.play("deny")
	else:
		board.sfx.play("tick")
	selected = null
	_select(part)
	if was_dragging:
		drag_part = part
		_update_drag_tint()
	else:
		_commit()


func _rotate_selected(sign_value: float) -> void:
	if selected == null:
		return
	var setting := selected.setting()
	if not setting.is_empty():
		var value: float = selected.entry.get(setting.key, setting.default)
		value = clampf(value + setting.step * sign_value, setting.min, setting.max)
		_edit_selected(setting.key, value)
		_status.text = selected.describe()[-1]
		return
	if selected.rotate_step() <= 0.0:
		return
	var rot: float = selected.entry.get("rot", 0.0) + selected.rotate_step() * sign_value
	_edit_selected("rot", fposmod(rot, 360.0))


func _flip_selected() -> void:
	if selected != null and selected.can_flip():
		_edit_selected("dir", -selected.dir)


func _cycle_channel() -> void:
	if selected == null or not selected.uses_channel():
		return
	var r := selected.channel_range()
	var next := selected.channel + 1
	_edit_selected("channel", r.x if next > r.y else next)


func _remove_selected() -> void:
	if selected != null:
		var part := selected
		_select(null)
		board.remove(part)
		board.sfx.play("remove")
		_commit()


# --- Construction de l'interface ------------------------------------------------

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(1280, TOP_H)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	_level_picker = OptionButton.new()
	_level_picker.custom_minimum_size.x = 270
	_level_picker.item_selected.connect(load_level)
	row.add_child(_level_picker)

	_goal_label = Label.new()
	_goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_goal_label)

	_sound_button = Button.new()
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.pressed.connect(_toggle_sound)
	row.add_child(_sound_button)

	var hint := Button.new()
	hint.text = "Indice"
	hint.focus_mode = Control.FOCUS_NONE
	hint.pressed.connect(func() -> void:
		_status.text = levels[current].get("hint", "")
		if levels[current].has("tutorial") and not board.running:
			_start_tutorial())
	row.add_child(hint)

	_clear_button = Button.new()
	_clear_button.text = "Tout retirer"
	_clear_button.focus_mode = Control.FOCUS_NONE
	_clear_button.pressed.connect(func() -> void:
		_select(null)
		_cancel_rope()
		board.clear_placed()
		board.sfx.play("remove")
		_commit())
	row.add_child(_clear_button)

	_run_button = Button.new()
	_run_button.custom_minimum_size.x = 110
	_run_button.focus_mode = Control.FOCUS_NONE
	_run_button.pressed.connect(toggle_run)
	row.add_child(_run_button)


func _build_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(PANEL_X, TOP_H)
	panel.size = Vector2(1280.0 - PANEL_X, 720.0 - TOP_H)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Pièces disponibles"
	col.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_bin = VBoxContainer.new()
	_bin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_bin)

	col.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 2
	col.add_child(grid)
	for def: Array in [
		["undo", "Annuler", _undo, "Ctrl+Z"],
		["redo", "Rétablir", _redo, "Ctrl+Y"],
		["rotate", "Pivoter (R)", func() -> void: _rotate_selected(1.0)],
		["flip", "Miroir (F)", _flip_selected],
		["channel", "Canal (C)", _cycle_channel],
		["remove", "Retirer", _remove_selected],
	]:
		var b := Button.new()
		b.text = def[1]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(def[2])
		if def.size() > 3:
			b.tooltip_text = def[3]
		grid.add_child(b)
		_ctx_buttons[def[0]] = b


func _build_status_bar() -> void:
	_status = Label.new()
	_status.position = Vector2(10, TOP_H + Board.SIZE.y)
	_status.size = Vector2(PANEL_X - 20.0, 720.0 - TOP_H - Board.SIZE.y)
	_status.clip_text = true
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	add_child(_status)


func _build_win_overlay() -> void:
	_win_overlay = ColorRect.new()
	(_win_overlay as ColorRect).color = Color(0.05, 0.08, 0.14, 0.72)
	_win_overlay.position = Vector2(0, TOP_H)
	_win_overlay.size = Vector2(PANEL_X, 720.0 - TOP_H)
	_win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_win_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var label := Label.new()
	label.text = "La machine fonctionne !"
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Part.GOLD)
	box.add_child(label)
	_win_bonus = Label.new()
	_win_bonus.add_theme_font_size_override("font_size", 17)
	box.add_child(_win_bonus)
	_win_next = Button.new()
	_win_next.pressed.connect(func() -> void:
		load_level((current + 1) % levels.size()))
	box.add_child(_win_next)
	var again := Button.new()
	again.text = "Revenir à l'atelier"
	again.pressed.connect(toggle_run)
	box.add_child(again)
	_win_overlay.hide()


func _make_theme() -> Theme:
	var t := Theme.new()
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("2a3a57")
	flat.set_content_margin_all(8.0)
	t.set_stylebox("panel", "PanelContainer", flat)
	t.set_font_size("font_size", "Label", 15)
	t.set_font_size("font_size", "Button", 15)
	return t


# --- Mise à jour de l'interface -------------------------------------------------

func _rebuild_bin() -> void:
	for item in _items:
		item.free()
	_items.clear()
	var inventory: Dictionary = levels[current].get("inventory", {})
	for kind in BIN_ORDER:
		if inventory.has(kind):
			var item := BinItem.new()
			item.setup(kind)
			item.grabbed.connect(_grab_from_bin)
			_bin.add_child(item)
			_items.append(item)
	_refresh_bin()


func _refresh_bin() -> void:
	for item in _items:
		item.update_count(board.remaining(item.kind), not board.running)
	_refresh_context()


func _refresh_context() -> void:
	if _ctx_buttons.is_empty():
		return
	var p := selected if is_instance_valid(selected) else null
	var adjustable := p != null and not p.setting().is_empty()
	_ctx_buttons.rotate.disabled = p == null or (p.rotate_step() <= 0.0 and not adjustable)
	_ctx_buttons.rotate.text = p.setting().label if adjustable else "Pivoter (R)"
	_ctx_buttons.flip.disabled = p == null or not p.can_flip()
	_ctx_buttons.channel.disabled = p == null or not p.uses_channel()
	_ctx_buttons.remove.disabled = p == null
	var history := _history() if histories.has(levels[current].id) else null
	_ctx_buttons.undo.disabled = board.running or history == null or not history.can_undo()
	_ctx_buttons.redo.disabled = board.running or history == null or not history.can_redo()


func _refresh_controls() -> void:
	_run_button.text = "Arrêter" if board.running else "Lancer"
	_clear_button.disabled = board.running
	_sound_button.text = "Son : non" if muted else "Son : oui"
	AudioServer.set_bus_mute(0, muted)


func _refresh_level_picker() -> void:
	_level_picker.clear()
	for i in levels.size():
		var mark := "[OK] " if completed.has(levels[i].id) else ""
		_level_picker.add_item("%s%d. %s%s" % [mark, i + 1, levels[i].name, _stars(levels[i])])
	_level_picker.select(current)


## Étoiles des objectifs bonus : pleines pour ceux obtenus.
func _stars(level: Dictionary) -> String:
	var offered := Bonus.offered(level)
	if offered.is_empty() or not completed.has(level.id):
		return ""
	var got: Array = bonuses.get(level.id, [])
	var text := "  "
	for kind in offered:
		text += "★" if got.has(kind) else "☆"
	return text


func _on_won() -> void:
	var level: Dictionary = levels[current]
	completed[level.id] = true
	var got: Array = bonuses.get(level.id, [])
	var now := Bonus.earned(level, board.placed.size(), board.elapsed)
	var lines: PackedStringArray = []
	for kind in Bonus.offered(level):
		var mark := "★ " if now.has(kind) else "☆ "
		var fresh := now.has(kind) and not got.has(kind)
		lines.append(mark + Bonus.describe(kind, level) + ("  (nouveau !)" if fresh else ""))
		if now.has(kind) and not got.has(kind):
			got.append(kind)
	bonuses[level.id] = got
	lines.append("Temps : %s s, pièces posées : %d" % [String.num(board.elapsed, 1).replace(".", ","),
			board.placed.size()])
	_win_bonus.text = "\n".join(lines)
	_save_progress()
	_refresh_level_picker()
	board.sfx.play("win")
	var last := current == levels.size() - 1
	_win_next.text = "Rejouer le premier niveau" if last else "Niveau suivant"
	_win_overlay.show()


# --- Tutoriel intégré -----------------------------------------------------------

func _start_tutorial() -> void:
	if levels[current].has("tutorial"):
		tutorial.start(levels[current].tutorial)


func _on_tutorial_finished(_skipped: bool) -> void:
	tutorials_done[levels[current].id] = true
	_save_progress()


## Conditions d'avancement : "running", "stopped", "won", "placed:pièce[:nombre]",
## "rot:pièce:min:max" (degrés), "rope_tool", "rope_from".
func _tutorial_condition(name: String) -> bool:
	var args := name.split(":")
	match args[0]:
		"running":
			return board.running
		"stopped":
			return not board.running
		"won":
			return board.has_won or _win_overlay.visible
		"placed":
			return _count_placed(args[1]) >= (args[2].to_int() if args.size() > 2 else 1)
		"rot":
			for entry: Dictionary in board.placed:
				var rot: float = entry.get("rot", 0.0)
				if entry.kind == args[1] and rot >= args[2].to_float() and rot <= args[3].to_float():
					return true
			return false
		"rope_tool":
			return rope_tool or _count_placed("rope") > 0
		"rope_from":
			return rope_from != null or _count_placed("rope") > 0
	push_error("Condition de tutoriel inconnue : %s" % name)
	return false


func _count_placed(kind: String) -> int:
	var count := 0
	for entry: Dictionary in board.placed:
		if entry.kind == kind:
			count += 1
	return count


## Cibles : "run", "bin:pièce", "ctx:action", "part:identifiant", "zone:x,y,l,h" (plateau).
func _tutorial_target(name: String) -> Rect2:
	var args := name.split(":")
	match args[0]:
		"run":
			return _run_button.get_global_rect()
		"bin":
			for item in _items:
				if item.kind == args[1]:
					return item.get_global_rect()
		"ctx":
			return (_ctx_buttons[args[1]] as Control).get_global_rect()
		"part":
			var part := board.find_part(args[1])
			if part != null and is_instance_valid(part.main_body):
				return Rect2(part.main_body.global_position - Vector2(28, 28), Vector2(56, 56))
		"zone":
			var v := args[1].split_floats(",")
			return Rect2(board.to_global(Vector2(v[0], v[1])), Vector2(v[2], v[3]))
	return Rect2()


func _tutorial_obstacles() -> Array:
	var rects: Array = []
	for part in board.parts:
		for solid in part.solids:
			rects.append(solid.global_transform * solid.shape.get_rect())
	for item in _items:
		rects.append(item.get_global_rect())
	for button: Control in _ctx_buttons.values():
		rects.append(button.get_global_rect())
	return rects


# --- Progression ----------------------------------------------------------------

func _toggle_sound() -> void:
	muted = not muted
	_refresh_controls()
	_save_progress()


func _first_unsolved() -> int:
	for i in levels.size():
		if not completed.has(levels[i].id):
			return i
	return 0


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		for id: String in cfg.get_value("progress", "completed", []):
			completed[id] = true
		muted = cfg.get_value("settings", "muted", false)
		saved_layouts = cfg.get_value("layouts", "by_level", {})
		for id: String in cfg.get_value("progress", "tutorials", []):
			tutorials_done[id] = true
		bonuses = cfg.get_value("progress", "bonuses", {})


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed.keys())
	cfg.set_value("progress", "tutorials", tutorials_done.keys())
	cfg.set_value("progress", "bonuses", bonuses)
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("layouts", "by_level", saved_layouts)
	cfg.save(save_path)
