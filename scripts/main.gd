extends Control
## Interface : barre du haut, bac à pièces, glisser-déposer et écran de victoire.
## Toute la mécanique de jeu vit dans Board.

const TOP_H := 56.0
const PANEL_X := 1040.0
const BIN_ORDER: Array[String] = [
	"plank", "domino", "spring", "seesaw", "conveyor", "fan", "plate", "cannon",
	"ball", "ball_bouncy", "ball_heavy", "crate", "balloon", "spikes",
]

var save_path := "user://progress.cfg"
var board: Board
var levels: Array = []
var current := 0
var completed := {}

var selected: Part
var drag_part: Part
var drag_is_new := false
var drag_origin := Vector2.ZERO

var _level_picker: OptionButton
var _run_button: Button
var _clear_button: Button
var _goal_label: Label
var _status: Label
var _bin: VBoxContainer
var _items: Array[BinItem] = []
var _ctx_buttons := {}
var _win_overlay: Control
var _win_next: Button
var _mouse := Vector2.ZERO


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

	_build_top_bar()
	_build_side_panel()
	_build_status_bar()
	_build_win_overlay()
	load_level(_first_unsolved())


func load_level(index: int) -> void:
	_stop_drag()
	current = index
	_select(null)
	_win_overlay.hide()
	board.load_level(levels[index])
	_goal_label.text = levels[index].goal_text
	_status.text = levels[index].get("intro", "")
	_rebuild_bin()
	_refresh_level_picker()
	_refresh_controls()


func toggle_run() -> void:
	_stop_drag()
	_select(null)
	_win_overlay.hide()
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
		_handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed:
		_handle_click(event.button_index)


func _handle_key(key: Key) -> void:
	match key:
		KEY_SPACE:
			toggle_run()
		KEY_R:
			_rotate_selected(1.0)
		KEY_F:
			_flip_selected()
		KEY_C:
			_cycle_channel()
		KEY_DELETE, KEY_BACKSPACE:
			_remove_selected()


func _handle_click(button: MouseButton) -> void:
	if board.running:
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
				drag_part = target
				drag_is_new = false
				drag_origin = target.position
			else:
				_select(null)


func _to_board(screen_pos: Vector2) -> Vector2:
	return board.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _is_player_part(part: Part) -> bool:
	return part != null and board.placed.has(part.entry)


# --- Glisser-déposer ------------------------------------------------------------

func _grab_from_bin(kind: String) -> void:
	if board.running or board.remaining(kind) <= 0:
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
		return
	if drag_is_new:
		_select(null)
		board.remove(part)
		_status.text = "Pas de place ici : la pièce retourne dans le bac."
	else:
		board.move_part(part, drag_origin)
		_status.text = "Pas de place ici : la pièce reprend sa position."


func _stop_drag() -> void:
	if drag_part != null:
		_drop()


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
	selected = null
	_select(part)
	if was_dragging:
		drag_part = part
		_update_drag_tint()


func _rotate_selected(sign_value: float) -> void:
	if selected == null or selected.rotate_step() <= 0.0:
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

	var hint := Button.new()
	hint.text = "Indice"
	hint.focus_mode = Control.FOCUS_NONE
	hint.pressed.connect(func() -> void: _status.text = levels[current].get("hint", ""))
	row.add_child(hint)

	_clear_button = Button.new()
	_clear_button.text = "Tout retirer"
	_clear_button.focus_mode = Control.FOCUS_NONE
	_clear_button.pressed.connect(func() -> void:
		_select(null)
		board.clear_placed())
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
	_ctx_buttons.rotate.disabled = p == null or p.rotate_step() <= 0.0
	_ctx_buttons.flip.disabled = p == null or not p.can_flip()
	_ctx_buttons.channel.disabled = p == null or not p.uses_channel()
	_ctx_buttons.remove.disabled = p == null


func _refresh_controls() -> void:
	_run_button.text = "Arrêter" if board.running else "Lancer"
	_clear_button.disabled = board.running


func _refresh_level_picker() -> void:
	_level_picker.clear()
	for i in levels.size():
		var mark := "[OK] " if completed.has(levels[i].id) else ""
		_level_picker.add_item("%s%d. %s" % [mark, i + 1, levels[i].name])
	_level_picker.select(current)


func _on_won() -> void:
	completed[levels[current].id] = true
	_save_progress()
	_refresh_level_picker()
	var last := current == levels.size() - 1
	_win_next.text = "Rejouer le premier niveau" if last else "Niveau suivant"
	_win_overlay.show()


# --- Progression ----------------------------------------------------------------

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


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed.keys())
	cfg.save(save_path)
