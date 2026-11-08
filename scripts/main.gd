extends Control
## Interface : barre du haut, bac à pièces, glisser-déposer et écran de victoire.
## Toute la mécanique de jeu vit dans Board.

const TOP_H := 56.0
const PANEL_X := 1040.0
const BIN_ORDER: Array[String] = [
	"plank", "domino", "spring", "seesaw", "conveyor", "fan", "plate", "switch", "timer", "trapdoor", "door", "scissors", "magnet", "magnet_repel", "motor", "gear", "portal", "water", "suction", "cart", "mousewheel", "cat",
	"cannon",
	"pulley", "rope", "elastic", "ball", "ball_bouncy", "ball_heavy", "crate", "balloon", "spikes", "candle", "funnel", "pipe",
	"lamp", "basket",
]
## Réglages proposés dans le bac à sable.
const SANDBOX_GRAVITY: Array[float] = [1.0, 0.4, 0.1, 1.8]
const SANDBOX_WIND: Array[Vector2] = [Vector2.ZERO, Vector2(150, 0), Vector2(-150, 0), Vector2(0, -150)]

var save_path := "user://progress.cfg"
## « Mes niveaux » : un fichier de niveau par niveau personnel, dans les données du joueur.
var custom_dir := "user://niveaux"
var board: Board
var levels: Array = []
var current := 0
var completed := {}
## Objectifs bonus obtenus, par niveau : identifiant → liste de types (voir Bonus).
var bonuses := {}
## Palier d'indice atteint par niveau : 1 texte (gratuit), 2 pièce clé (une étoile de moins),
## 3 solution complète (plus d'étoile à gagner).
var hint_levels := {}
## Records personnels par niveau : {"time": meilleur temps, "parts": moins de pièces posées}.
var records := {}
var _hint_button: Button
var _hint_confirm: ConfirmationDialog

var selected: Part
var drag_part: Part
var drag_is_new := false
var drag_origin := Vector2.ZERO
## Sélection multiple (Maj+clic, Ctrl+A) : toutes les pièces choisies, `selected` compris.
var group: Array[Part] = []
## Pendant le glisser d'un groupe : position de départ de chaque pièce.
var _group_origins: Dictionary = {}
## Entrées copiées par Ctrl+C, cordes comprises quand leurs deux bouts sont copiés.
var clipboard: Array = []

var rope_tool := false
## Lien en cours de pose avec l'outil corde : "rope" ou "elastic".
var rope_kind := "rope"
var rope_from: Part
var rope_from_off := Vector2.ZERO
var rope_via: Array = []
var muted := false

var histories := {}
var saved_layouts := {}
## Tutoriels terminés ou passés : ils ne se relancent plus d'eux-mêmes (le bouton Indice, si).
var tutorials_done := {}
var show_tutorials := true
## Écran titre au démarrage ; les tests le passent.
var show_title := true
var title_screen: TitleScreen
## Dossier des niveaux du jeu que l'éditeur peut ouvrir et écrire ; vide : fonction cachée (jeu
## exporté, où `levels/` est en lecture seule).
var official_dir := LevelFile.DIR if OS.has_feature("editor") else ""
var official_dialog: OfficialDialog
var gallery_screen: GalleryScreen
var gallery_entries: Array = []
## Copie de la galerie téléchargée par « Actualiser en ligne ».
var gallery_online_path := "user://galerie_en_ligne.cfg"
var gallery_url := Gallery.ONLINE_URL
var _gallery_http: HTTPRequest
## Lancements de chaque niveau avant sa première victoire : la difficulté vécue par le joueur.
var attempts := {}
var transition: LevelTransition
var _started := false
var tutorial: Tutorial
## Niveaux créés dans l'éditeur, enregistrés avec la progression.
var custom_levels: Array = []
var editor: LevelEditor
## Brouillon de l'éditeur (nom, objectif, inventaire), gardé entre deux sessions.
var _editor_draft := {}
## Niveau construit par « Essayer », joué depuis l'éditeur.
var _test_level := {}

var _level_button: Button
var _level_select: LevelSelect
var _run_button: Button
var _clear_button: Button
var _speed_button: Button
var _pause_button: Button
## Vitesse de la simulation (1, 2 ou 4), appliquée seulement pendant qu'elle tourne.
var speed := 1
var paused := false
var _goal_label: Label
var _status: Label
var _bin: VBoxContainer
var _items: Array[BinItem] = []
var _ctx_buttons := {}
var _win_overlay: Control
var _win_bonus: Label
var _gravity_button: Button
var _wind_button: Button
var _win_next: Button
var _edit_button: Button
var _share_solution: Button
var share_dialog: ShareDialog
var verifier: Verifier
var recorder: Recorder
## Relecture en cours après une victoire : "watch", "gif" ou "video" ; vide sinon.
var replay_mode := ""
var last_recording := ""
## Numéro de la relecture en cours : un minuteur d'une relecture passée ne doit pas clore la suivante.
var _replay_token := 0
var _replay_row: HBoxContainer
var _open_folder: Button
var _rope_preview: Line2D
var _sound_button: Button
var _mouse := Vector2.ZERO
var _tooltip: PanelContainer
var _tooltip_label: Label
var _hovered: Part
var _hover_time := 0.0
var chrono: Chrono


func _ready() -> void:
	_load_progress()
	_assemble_levels()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()

	board = Board.new()
	board.position = Vector2(0, TOP_H)
	add_child(board)
	board.won.connect(_on_won)
	board.inventory_changed.connect(_refresh_bin)
	board.running_changed.connect(_refresh_speed)
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
	share_dialog = ShareDialog.new()
	add_child(share_dialog)
	share_dialog.import_requested.connect(import_code)
	verifier = Verifier.new()
	add_child(verifier)
	recorder = Recorder.new()
	add_child(recorder)
	_build_level_select()
	gallery_screen = GalleryScreen.new()
	add_child(gallery_screen)
	gallery_screen.play_requested.connect(_play_gallery)
	gallery_screen.refresh_requested.connect(_refresh_gallery)
	gallery_screen.propose_requested.connect(func() -> void:
		var proposal := gallery_proposal()
		if proposal.begins_with("https://"):
			OS.shell_open(proposal)
			gallery_screen.message.text = "La page de proposition s'ouvre dans ton navigateur : complète-la et envoie-la."
		else:
			gallery_screen.message.text = proposal)
	_gallery_http = HTTPRequest.new()
	_gallery_http.timeout = 15.0
	add_child(_gallery_http)
	_gallery_http.request_completed.connect(_on_gallery_downloaded)
	transition = LevelTransition.new()
	add_child(transition)
	title_screen = TitleScreen.new()
	add_child(title_screen)
	title_screen.play.connect(func() -> void: _enter(_first_unsolved()))
	title_screen.choose.connect(open_level_select)
	title_screen.sandbox.connect(func() -> void: _enter(_index_of("bac_a_sable")))
	title_screen.editor.connect(func() -> void: _enter(editor_index()))
	title_screen.gallery.connect(open_gallery)
	title_screen.hide()
	editor.load_from(_editor_draft)
	load_level(_first_unsolved())
	if show_title:
		open_title()
	_started = true


## Ouvre l'écran titre, avec la progression du joueur.
func open_title() -> void:
	_stop_drag()
	_cancel_rope()
	_hide_tooltip()
	_level_select.hide()
	var total := 0
	var done := 0
	var stars := 0
	for level: Dictionary in levels:
		if level.get("sandbox", false) or level.get("custom", false) or level.get("hidden", false):
			continue
		total += 1
		if completed.has(level.id):
			done += 1
			stars += bonuses.get(level.id, []).size()
	var progress := "%d / %d niveaux terminés" % [done, total]
	if stars > 0:
		progress += "  ·  %d ★" % stars
	title_screen.open(progress, not completed.is_empty() or not saved_layouts.is_empty())


## Entrée dans un niveau depuis l'écran titre : il se referme en fondu, la carte du niveau suit.
func _enter(index: int) -> void:
	if index < 0:
		return
	load_level(index)
	_announce(null)


func _index_of(id: String) -> int:
	return levels.find_custom(func(level: Dictionary) -> bool: return level.id == id)


## Carte du niveau courant, après le balayage de l'écran précédent s'il y en a une photo.
func _announce(shot: Texture2D) -> void:
	var level: Dictionary = levels[current]
	var world := LevelData.world(level.get("world", "atelier"))
	var line := ""
	if level.get("sandbox", false):
		line = "Construis librement"
	elif level.has("world"):
		line = "%s  ·  niveau %d" % [world.name, current + 1]
	transition.play(shot, line, level.name, world.color, Rect2(Vector2(0, TOP_H), Board.SIZE))


## Ordre des niveaux : ceux du jeu, le bac à sable, les niveaux personnels, puis l'éditeur et
## l'essai en cours, qui n'ont pas de vignette.
func _assemble_levels() -> void:
	var physics := _editor_physics()
	levels = LevelData.all()
	levels.append(LevelData.sandbox())
	levels.append_array(custom_levels)
	var editor_level := LevelData.editor_level()
	editor_level.merge(physics, true)
	levels.append(editor_level)
	if _test_level.is_empty():
		_test_level = {"id": "essai_editeur", "name": "Essai", "goal_text": "", "fixed": [],
				"inventory": {}, "hidden": true, "world": "perso"}
	levels.append(_test_level)


func _build_level_select() -> void:
	if _level_select != null:
		_level_select.queue_free()
	_level_select = LevelSelect.new()
	add_child(_level_select)
	_level_select.setup(levels)
	_level_select.chosen.connect(load_level)
	_level_select.import_requested.connect(func() -> void: share_dialog.show_import())
	_level_select.title_requested.connect(func() -> void: open_title())
	_level_select.gallery_requested.connect(func() -> void: open_gallery())


## Gravité et vent du plan de travail : ceux de la partie en cours, sinon ceux du brouillon.
func _editor_physics() -> Dictionary:
	var source: Dictionary = levels[editor_index()] if levels.size() >= 2 else _editor_draft
	return {"gravity": source.get("gravity", 1.0), "wind": source.get("wind", Vector2.ZERO)}


func editor_index() -> int:
	return levels.size() - 2


func test_index() -> int:
	return levels.size() - 1


func is_editor() -> bool:
	return levels[current].get("editor", false)


func is_testing() -> bool:
	return levels[current].get("id", "") == "essai_editeur"


## Rappel des conditions inhabituelles du niveau, à la suite de l'objectif.
static func _physics_note(level: Dictionary) -> String:
	if level.get("sandbox", false):
		return ""  # Les boutons du bac à sable affichent déjà ces réglages.
	var notes: PackedStringArray = []
	var g: float = level.get("gravity", 1.0)
	if g < 1.0:
		notes.append("gravité faible (×%s)" % String.num(g, 2).replace(".", ","))
	elif g > 1.0:
		notes.append("gravité forte (×%s)" % String.num(g, 2).replace(".", ","))
	var w: Vector2 = level.get("wind", Vector2.ZERO)
	if w != Vector2.ZERO:
		notes.append("vent " + _wind_arrow(w))
	return "" if notes.is_empty() else "  —  " + ", ".join(notes)


static func _wind_arrow(w: Vector2) -> String:
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][wrapi(roundi(w.angle() / (PI / 4.0)), 0, 8)]


func load_level(index: int) -> void:
	# Changement de niveau en jeu : photo de l'écran actuel pour le balayage de transition.
	var animate := _started and index != current and not title_screen.visible
	var shot := transition.snapshot() if animate else null
	_stop_drag()
	_hide_tooltip()
	_cancel_rope()
	current = index
	_select(null)
	_win_overlay.hide()
	board.load_level(levels[index])
	_show_hint_pieces()
	var level_id: String = levels[index].id
	var dropped := board.restore_layout(saved_layouts.get(level_id, []))
	if not histories.has(level_id):
		histories[level_id] = History.new(board.layout())
	_goal_label.text = levels[index].goal_text + _physics_note(levels[index])
	chrono.reset(levels[index].get("par_time", 0.0))
	_status.text = levels[index].get("intro", "")
	if not board.placed.is_empty():
		_status.text = "Ta machine a été remise en place. Ctrl+Z annule ta dernière action."
	if dropped > 0:
		_status.text = "%d pièce(s) sauvegardée(s) ne sont plus valides dans ce niveau." % dropped
	_rebuild_bin()
	_refresh_level_picker()
	_refresh_controls()
	editor.visible = is_editor()
	editor.official_box.visible = official_dir != ""
	editor.refresh()
	_refresh_proof()
	tutorial.stop()
	if show_tutorials and levels[index].has("tutorial") and not completed.has(level_id) \
			and not tutorials_done.has(level_id):
		_start_tutorial.call_deferred()
	if animate:
		_announce(shot)


## Vitesse suivante : ×1, ×2, ×4, puis de nouveau ×1.
func cycle_speed() -> void:
	set_speed(2 if speed == 1 else 4 if speed == 2 else 1)


func set_speed(value: int) -> void:
	speed = value
	_refresh_speed()


func toggle_pause() -> void:
	if board.running:
		paused = not paused
		_refresh_speed()


func _exit_tree() -> void:
	# Le moteur est global : on le rend tel qu'on l'a trouvé.
	speed = 1
	paused = false
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	PhysicsServer2D.set_active(true)


## Accélère la simulation sans changer son résultat : le moteur fait plus de pas par seconde,
## mais chaque pas couvre toujours le même temps (1/120 s). En pause, le moteur physique et le
## plateau sont gelés. À l'arrêt, tout revient à la normale pour l'interface.
func _refresh_speed() -> void:
	if not board.running:
		paused = false
	_pause_button.text = "Reprendre" if paused else "Pause"
	_pause_button.disabled = not board.running
	_speed_button.text = "×%d" % speed
	_apply_speed()


func _apply_speed() -> void:
	var base: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	var factor := speed if board.running and not paused else 1
	Engine.time_scale = factor
	Engine.physics_ticks_per_second = base * factor
	Engine.max_physics_steps_per_frame = maxi(8, 4 * factor)
	var frozen := board.running and paused
	PhysicsServer2D.set_active(not frozen)
	board.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT


func toggle_run() -> void:
	if replay_mode != "":
		_finish_replay()
	_stop_drag()
	_cancel_rope()
	_select(null)
	_win_overlay.hide()
	board.sfx.play("stop" if board.running else "start")
	if board.running:
		board.stop()
	else:
		_count_attempt()
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
		_handle_click(event.button_index, event.shift_pressed)


func _handle_key(event: InputEventKey) -> void:
	if title_screen.is_open():
		return
	if gallery_screen.visible:
		if event.keycode == KEY_ESCAPE:
			gallery_screen.hide()
		return
	if _level_select.visible:
		if event.keycode in [KEY_ESCAPE, KEY_TAB]:
			_level_select.hide()
		return
	if event.is_command_or_control_pressed():
		match event.keycode:
			KEY_Z:
				_redo() if event.shift_pressed else _undo()
			KEY_Y:
				_redo()
			KEY_C:
				copy_selection()
			KEY_V:
				paste()
			KEY_A:
				select_all()
		return
	match event.keycode:
		KEY_SPACE:
			toggle_run()
		KEY_M:
			_toggle_sound()
		KEY_P:
			toggle_pause()
		KEY_T:
			board.show_ghost = not board.show_ghost
			_status.text = "Trace du dernier essai : " + ("affichée." if board.show_ghost else "masquée (T pour la revoir).")
		KEY_V:
			cycle_speed()
		KEY_TAB:
			open_level_select()
		KEY_G:
			_toggle_goal()
		KEY_ESCAPE:
			if rope_tool:
				_cancel_rope()
				_status.text = "Corde annulée."
			elif selected != null:
				_select(null)
			else:
				open_title()
		KEY_R:
			_rotate_selected(-1.0 if event.shift_pressed else 1.0)
		KEY_F:
			_flip_selected()
		KEY_C:
			_cycle_channel()
		KEY_DELETE, KEY_BACKSPACE:
			_remove_selected()


func _handle_click(button: MouseButton, shift := false) -> void:
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
			if not _is_player_part(target):
				if not shift:
					_select(null)
			elif shift:
				_toggle_in_group(target)
			elif group.size() > 1 and group.has(target):
				_start_group_drag(target)
			else:
				_select(target)
				if not target is RopePart:
					drag_part = target
					drag_is_new = false
					drag_origin = target.position


func _to_board(screen_pos: Vector2) -> Vector2:
	return board.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _is_player_part(part: Part) -> bool:
	return part != null and board.placed.has(part.entry)


# --- Infobulles du plateau ------------------------------------------------------

const TOOLTIP_DELAY := 0.5


func _process(delta: float) -> void:
	chrono.track(board.running, board.has_won, board.elapsed)
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
	if event is InputEventMouseButton or drag_part != null or _level_select.visible \
			or title_screen.visible or gallery_screen.visible:
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
	if Catalog.is_link(kind):
		_select(null)
		rope_tool = true
		rope_kind = kind
		_status.text = "%s : clique le premier objet à relier (Échap pour annuler)." % Catalog.INFO[kind].label
		return
	drag_part = board.place(kind, _mouse)
	drag_is_new = true
	_select(drag_part)
	_update_drag_tint()


func _drag_to(pos: Vector2) -> void:
	if _group_origins.is_empty():
		board.move_part(drag_part, pos)
	else:
		var delta := board.snap(pos) - drag_origin
		for p: Part in _group_origins:
			board.move_part(p, _group_origins[p] + delta)
	_update_drag_tint()


func _update_drag_tint() -> void:
	var moving: Array = [drag_part] if _group_origins.is_empty() else _group_origins.keys()
	for p: Part in moving:
		p.modulate = Color.WHITE if board.is_valid(p) else Color(1, 0.35, 0.35, 0.8)


func _start_group_drag(target: Part) -> void:
	_group_origins.clear()
	for p in group:
		if not p is RopePart:
			_group_origins[p] = p.position
	drag_part = target
	drag_is_new = false
	drag_origin = target.position


## Lâcher d'un groupe : tout le groupe se pose, ou tout reprend sa place.
func _drop_group() -> void:
	drag_part = null
	var origins := _group_origins
	_group_origins = {}
	var ok := true
	for p: Part in origins:
		p.modulate = Color.WHITE
		ok = ok and board.is_valid(p)
	if ok:
		board.sfx.play("place")
	else:
		board.sfx.play("deny")
		for p: Part in origins:
			board.move_part(p, origins[p])
		_status.text = "Pas de place ici : les pièces reprennent leur position."
	_commit()


func _drop() -> void:
	if not _group_origins.is_empty():
		_drop_group()
		return
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
	board.add_rope(rope_from, rope_from_off, rope_via.duplicate(), target, off, rope_kind)
	board.sfx.play("place")
	_cancel_rope()
	_commit()
	_status.text = "Élastique posé. Sélectionne-le et appuie sur R pour le tendre." if rope_kind == "elastic" \
			else "Corde posée, tendue. Sélectionne-la et appuie sur R pour lui donner du mou."


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
	_refresh_proof()


## Dans l'éditeur : le plan de travail actuel a-t-il déjà été résolu ?
func _refresh_proof() -> void:
	if editor != null and is_editor():
		editor.show_proof(_draft_level())


func _draft_level() -> Dictionary:
	return LevelData.from_editor("", "", "", board.layout(), editor.inventory, board.gravity_factor(),
			board.wind())


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
	for p in group:
		if is_instance_valid(p):
			p.selected = false
	group.clear()
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
		if old == null:
			part.entry.erase(key)
		else:
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
	var parts := _selection()
	if parts.is_empty():
		return
	_select(null)
	for part in parts:
		# Retirer un objet retire aussi ses cordes, qui peuvent faire partie du groupe.
		if board.placed.has(part.entry):
			board.remove(part)
	board.sfx.play("remove")
	_commit()


# --- Sélection multiple, copier-coller ------------------------------------------

## Les pièces du joueur actuellement choisies : le groupe, ou la seule pièce sélectionnée.
func _selection() -> Array[Part]:
	var result: Array[Part] = []
	for p in group:
		if is_instance_valid(p) and _is_player_part(p):
			result.append(p)
	if result.is_empty() and is_instance_valid(selected) and _is_player_part(selected):
		result.append(selected)
	return result


func _set_group(parts: Array[Part]) -> void:
	_select(null)
	for p in parts:
		p.selected = true
	group = parts.duplicate()
	selected = parts[-1] if not parts.is_empty() else null
	_refresh_context()
	if parts.size() > 1:
		_status.text = "%d pièces sélectionnées : glisser pour les déplacer ensemble, Ctrl+C pour les copier." \
				% parts.size()


func _toggle_in_group(part: Part) -> void:
	var parts := _selection()
	if parts.has(part):
		parts.erase(part)
	else:
		parts.append(part)
	_set_group(parts)


func select_all() -> void:
	if board.running or drag_part != null or rope_tool:
		return
	var parts: Array[Part] = []
	for p in board.parts:
		if _is_player_part(p):
			parts.append(p)
	_set_group(parts)


func copy_selection() -> void:
	var parts := _selection()
	if parts.is_empty() or rope_tool:
		board.sfx.play("deny")
		return
	var ids := {}
	for p in parts:
		if not p is RopePart:
			ids[p.entry.id] = true
	clipboard.clear()
	for entry: Dictionary in board.placed:
		var keep: bool = ids.has(entry.id)
		if Catalog.is_link(entry.kind):
			keep = ids.has(entry.get("from", "")) and ids.has(entry.get("to", ""))
			for via: Variant in entry.get("via", []):
				keep = keep and ids.has(str(via))
		if keep:
			clipboard.append(entry.duplicate(true))
	board.sfx.play("tick")
	_status.text = "%d pièce(s) copiée(s) : Ctrl+V pour les coller sous la souris." % clipboard.size()


## Colle la copie centrée sous la souris (ou décalée, si la souris est hors du plateau), dans
## la limite du bac ; ce qui n'a pas de place reste dans le bac.
func paste() -> void:
	if board.running or drag_part != null or rope_tool or clipboard.is_empty():
		board.sfx.play("deny")
		return
	var objects: Array = clipboard.filter(func(e: Dictionary) -> bool: return not Catalog.is_link(e.kind))
	var center := Vector2.ZERO
	for entry: Dictionary in objects:
		center += entry.pos
	center /= maxf(objects.size(), 1.0)
	var on_board := Rect2(Vector2.ZERO, Board.SIZE).has_point(_mouse)
	var offset := board.snap((_mouse if on_board else center + Vector2(40, 40)) - center)
	var new_ids := {}
	var pasted: Array[Part] = []
	var skipped := 0
	for entry: Dictionary in clipboard:
		var link := Catalog.is_link(entry.kind)
		var wanted := entry.duplicate(true)
		if link:
			wanted.from = new_ids.get(entry.get("from", ""), "")
			wanted.to = new_ids.get(entry.get("to", ""), "")
			wanted.via = entry.get("via", []).map(func(id: Variant) -> String: return new_ids.get(str(id), ""))
			if wanted.from == "" or wanted.to == "" or wanted.via.has(""):
				skipped += 1
				continue
		if board.remaining(entry.kind) <= 0:
			skipped += 1
			continue
		var part := board.place(entry.kind, Vector2.ZERO if link else entry.pos + offset)
		wanted.id = part.entry.id
		wanted.pos = part.entry.pos
		part.entry.merge(wanted, true)
		part = board.rebuild_part(part)
		if not link and not board.is_valid(part):
			board.remove(part)
			skipped += 1
			continue
		new_ids[entry.id] = part.entry.id
		pasted.append(part)
	if pasted.is_empty():
		board.sfx.play("deny")
		_status.text = "Rien à coller ici : bac vide ou pas de place."
		return
	board.sfx.play("place")
	_commit()
	_set_group(pasted)
	_status.text = "%d pièce(s) collée(s)%s." % [pasted.size(),
			"" if skipped == 0 else ", %d restée(s) dans le bac (épuisé ou pas de place)" % skipped]


# --- Construction de l'interface ------------------------------------------------

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(1280, TOP_H)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	_level_button = Button.new()
	_level_button.custom_minimum_size.x = 270
	_level_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_level_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_level_button.focus_mode = Control.FOCUS_NONE
	_level_button.tooltip_text = "Choisir un autre niveau (Tab)"
	_level_button.pressed.connect(open_level_select)
	row.add_child(_level_button)

	_goal_label = Label.new()
	_goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_goal_label)

	_gravity_button = Button.new()
	_gravity_button.focus_mode = Control.FOCUS_NONE
	_gravity_button.pressed.connect(func() -> void: _cycle_sandbox_physics(1, 0))
	row.add_child(_gravity_button)
	_wind_button = Button.new()
	_wind_button.focus_mode = Control.FOCUS_NONE
	_wind_button.pressed.connect(func() -> void: _cycle_sandbox_physics(0, 1))
	row.add_child(_wind_button)

	_edit_button = Button.new()
	_edit_button.focus_mode = Control.FOCUS_NONE
	_edit_button.pressed.connect(func() -> void:
		if is_testing():
			load_level(editor_index())
		else:
			edit_level(levels[current]))
	row.add_child(_edit_button)

	_sound_button = Button.new()
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.pressed.connect(_toggle_sound)
	row.add_child(_sound_button)

	_hint_button = Button.new()
	_hint_button.text = "Indice"
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.pressed.connect(ask_hint)
	row.add_child(_hint_button)
	_hint_confirm = ConfirmationDialog.new()
	_hint_confirm.title = "Indice"
	_hint_confirm.ok_button_text = "Montrer"
	_hint_confirm.cancel_button_text = "Annuler"
	_hint_confirm.confirmed.connect(func() -> void: reveal_hint(_hint_level() + 1))
	add_child(_hint_confirm)

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

	chrono = Chrono.new()
	row.add_child(chrono)

	_pause_button = Button.new()
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.custom_minimum_size.x = 96
	_pause_button.tooltip_text = "Met la simulation en pause, ou la reprend (P)"
	_pause_button.pressed.connect(toggle_pause)
	row.add_child(_pause_button)
	_speed_button = Button.new()
	_speed_button.focus_mode = Control.FOCUS_NONE
	_speed_button.custom_minimum_size.x = 44
	_speed_button.tooltip_text = "Vitesse de la simulation : ×1, ×2 ou ×4 (V)"
	_speed_button.pressed.connect(cycle_speed)
	row.add_child(_speed_button)

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

	editor = LevelEditor.new()
	editor.visible = false
	col.add_child(editor)
	editor.try_requested.connect(_editor_try)
	editor.save_requested.connect(_editor_save)
	editor.delete_requested.connect(_editor_delete)
	editor.reset_requested.connect(_editor_reset)
	editor.share_requested.connect(_share_level)
	editor.open_official_requested.connect(_open_official)
	editor.physics_changed.connect(func(gravity: float, wind: Vector2) -> void:
		if board.running or not is_editor():
			return
		board.set_physics(gravity, wind)
		_refresh_proof()
		_refresh_controls()
		_save_progress())
	editor.save_official_requested.connect(_ask_save_official)
	official_dialog = OfficialDialog.new()
	add_child(official_dialog)
	official_dialog.opened.connect(edit_official)
	official_dialog.save_confirmed.connect(_save_official)
	editor.goal_button.pressed.connect(_toggle_goal)

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
	_win_next.pressed.connect(func() -> void: load_level(_next_index()))
	box.add_child(_win_next)
	_replay_row = HBoxContainer.new()
	_replay_row.add_theme_constant_override("separation", 8)
	box.add_child(_replay_row)
	for def: Array in [["Revoir", "watch"], ["Filmer en GIF", "gif"], ["Filmer en vidéo", "video"]]:
		var b := Button.new()
		b.text = def[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mode: String = def[1]
		b.pressed.connect(func() -> void: replay(mode))
		_replay_row.add_child(b)
	_open_folder = Button.new()
	_open_folder.text = "Ouvrir le dossier des enregistrements"
	_open_folder.pressed.connect(func() -> void:
		DirAccess.make_dir_recursive_absolute(Recorder.DIR)
		OS.shell_open(ProjectSettings.globalize_path(Recorder.DIR)))
	box.add_child(_open_folder)
	_share_solution = Button.new()
	_share_solution.text = "Partager ma solution…"
	_share_solution.pressed.connect(_share_my_solution)
	box.add_child(_share_solution)
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


## Fait défiler la gravité (dg) ou le vent (dw) parmi les réglages du bac à sable.
func _cycle_sandbox_physics(dg: int, dw: int) -> void:
	if board.running or not is_sandbox():
		return
	var g := SANDBOX_GRAVITY[(SANDBOX_GRAVITY.find(board.gravity_factor()) + dg) % SANDBOX_GRAVITY.size()]
	var w := SANDBOX_WIND[(SANDBOX_WIND.find(board.wind()) + dw) % SANDBOX_WIND.size()]
	board.set_physics(g, w)
	_refresh_proof()
	_refresh_controls()


func is_sandbox() -> bool:
	return levels[current].get("sandbox", false)


func _refresh_controls() -> void:
	_run_button.text = "Arrêter" if board.running else "Lancer"
	_refresh_speed()
	_clear_button.disabled = board.running
	_gravity_button.visible = is_sandbox()
	_wind_button.visible = is_sandbox()
	_gravity_button.disabled = board.running
	_wind_button.disabled = board.running
	var g := board.gravity_factor()
	_gravity_button.text = "Gravité : " + ("normale" if g == 1.0 else "×" + String.num(g, 1).replace(".", ","))
	var w := board.wind()
	_wind_button.text = "Vent : " + ("aucun" if w == Vector2.ZERO else _wind_arrow(w))
	_sound_button.text = "Son : non" if muted else "Son : oui"
	AudioServer.set_bus_mute(0, muted)
	_edit_button.visible = is_testing() or levels[current].get("custom", false)
	_edit_button.disabled = board.running
	_edit_button.text = "Retour à l'éditeur" if is_testing() else "Modifier"
	if editor != null and is_editor():
		editor.show_physics(board.gravity_factor(), board.wind())


func _refresh_level_picker() -> void:
	var level: Dictionary = levels[current]
	var world: String = LevelData.world(level.world).name + " · " if level.has("world") else ""
	_level_button.text = "☰  %s%d. %s%s" % [world, current + 1, level.name, _stars(level)]


## Ligne d'état d'une vignette : terminé ou non, étoiles des objectifs bonus.
func _level_status(level: Dictionary) -> String:
	if level.get("custom", false) and not level.get("verified", false):
		return "Non vérifié"
	if level.get("editor", false):
		return "Crée tes propres niveaux"
	if level.get("sandbox", false):
		return "Toutes les pièces, sans objectif"
	if is_locked(level):
		return "🔒 Toutes les étoiles du monde"
	if not completed.has(level.id):
		return "À faire"
	var record := record_text(level.id)
	return "Terminé" + _stars(level) + ("\n" + record if record != "" else "")


## Un niveau « défi » s'ouvre quand tous les autres niveaux de son monde sont terminés avec
## toutes leurs étoiles.
func is_locked(level: Dictionary) -> bool:
	if not level.get("challenge", false):
		return false
	for other: Dictionary in levels:
		if other.get("world", "") != level.get("world") or other.get("challenge", false) \
				or other.get("custom", false):
			continue
		if not completed.has(other.id):
			return true
		for kind in Bonus.offered(other):
			if not bonuses.get(other.id, []).has(kind):
				return true
	return false


func open_level_select() -> void:
	if _level_select.visible:
		_level_select.hide()
		return
	_stop_drag()
	_cancel_rope()
	_hide_tooltip()
	var statuses: Array = []
	var locked: Array = []
	for level: Dictionary in levels:
		statuses.append(_level_status(level))
		locked.append(is_locked(level))
	_level_select.open(current, statuses, locked)


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


# --- Records personnels -------------------------------------------------------------

## Garde le meilleur temps et le plus petit nombre de pièces ; rend ce qui vient d'être battu.
func _update_record(id: String, seconds: float, count: int) -> PackedStringArray:
	var record: Dictionary = records.get(id, {})
	var news := PackedStringArray()
	var first := record.is_empty()
	if first or seconds < record.time:
		record.time = snappedf(seconds, 0.01)
		if not first:
			news.append("temps")
	if first or count < record.parts:
		record.parts = count
		if not first:
			news.append("pièces")
	records[id] = record
	return news


func record_text(id: String) -> String:
	if not records.has(id):
		return ""
	var record: Dictionary = records[id]
	return "Record : %s s · %d pièce%s" % [String.num(record.time, 1).replace(".", ","), record.parts,
			"s" if record.parts > 1 else ""]


# --- Indices progressifs -------------------------------------------------------------

func _hint_level() -> int:
	return hint_levels.get(levels[current].id, 0)


## Bouton Indice : le texte d'abord, gratuitement ; ensuite, après confirmation, une pièce clé
## puis la solution complète, contre les étoiles du niveau.
func ask_hint() -> void:
	var level: Dictionary = levels[current]
	var step := _hint_level()
	if step == 0 or level.get("solution", []).is_empty() or level.get("custom", false) or step >= 3:
		reveal_hint(maxi(step, 1))
		return
	var stars := Bonus.offered(level).size()
	_hint_confirm.dialog_text = ("Montrer où va une pièce clé ?\nCe niveau ne pourra plus rapporter que %d étoile(s) sur %d." % [maxi(stars - 1, 0), stars]) \
			if step == 1 else "Montrer toute la solution ?\nCe niveau ne rapportera plus de nouvelle étoile."
	_hint_confirm.popup_centered()


func reveal_hint(step: int) -> void:
	var level: Dictionary = levels[current]
	var solution: Array = level.get("solution", [])
	if level.get("custom", false):
		solution = []  # Les niveaux personnels ne montrent pas la solution de leur auteur.
	step = clampi(step, 1, 3 if not solution.is_empty() else 1)
	if not level.get("sandbox", false):
		hint_levels[level.id] = maxi(_hint_level(), step)
		_save_progress()
	_status.text = level.get("hint", "")
	if step == 1 and level.has("tutorial") and not board.running:
		_start_tutorial()
	_show_hint_pieces()


## Pièces révélées selon le palier atteint, et libellé du bouton pour le palier suivant.
func _show_hint_pieces() -> void:
	var level: Dictionary = levels[current]
	var solution: Array = [] if level.get("custom", false) else level.get("solution", [])
	var step := _hint_level()
	board.show_hints(solution if step >= 3 else [_key_piece(solution)] if step == 2 and not solution.is_empty() else [])
	if step >= 2 and not solution.is_empty():
		_status.text = "Indice : les pointillés dorés montrent %s." % ("toute la solution" if step >= 3 else "où poser une pièce clé")
	_hint_button.text = "Indice" if step == 0 or solution.is_empty() else \
			"Indice +" if step == 1 else "Solution" if step == 2 else "Indice ✓"
	_hint_button.tooltip_text = "Un coup de pouce : le texte d'abord, puis une pièce clé, puis la solution (contre des étoiles)."


## La pièce la plus parlante de la solution : la première qui n'est ni planche ni corde.
static func _key_piece(solution: Array) -> Dictionary:
	for entry: Dictionary in solution:
		if entry.kind != "plank" and not Catalog.is_link(entry.kind):
			return entry
	return solution[0]


## Étoiles que le niveau peut encore rapporter, selon les indices pris.
func _star_cap(level: Dictionary) -> int:
	var total := Bonus.offered(level).size()
	match hint_levels.get(level.id, 0):
		2:
			return maxi(total - 1, 0)
		3:
			return 0
	return total


func _on_won() -> void:
	if replay_mode != "":
		# La relecture continue une seconde après la victoire, pour voir le dénouement.
		_finish_replay_after(1.0)
		return
	var level: Dictionary = levels[current]
	if level.get("sandbox", false):
		return  # Ni le bac à sable ni l'éditeur n'ont d'objectif à remplir.
	if is_testing():
		_on_test_won()
		return
	completed[level.id] = true
	var got: Array = bonuses.get(level.id, [])
	var now := Bonus.earned(level, board.placed.size(), board.elapsed)
	var lines: PackedStringArray = []
	var cap := _star_cap(level)
	for kind in Bonus.offered(level):
		var mark := "★ " if now.has(kind) else "☆ "
		var fresh := now.has(kind) and not got.has(kind) and got.size() < cap
		lines.append(mark + Bonus.describe(kind, level) + ("  (nouveau !)" if fresh else ""))
		if fresh:
			got.append(kind)
	bonuses[level.id] = got
	if cap < Bonus.offered(level).size():
		lines.append("Indices pris : ce niveau rapporte au plus %d étoile(s)." % cap)
	lines.append("Temps : %s s, pièces posées : %d" % [String.num(board.elapsed, 1).replace(".", ","),
			board.placed.size()])
	var news := _update_record(level.id, board.elapsed, board.placed.size())
	if not news.is_empty():
		lines.append("Nouveau record : " + " et ".join(news) + " !")
	_win_bonus.text = "\n".join(lines)
	_save_progress()
	_refresh_level_picker()
	board.sfx.play("win")
	var next: Dictionary = levels[_next_index()]
	_share_solution.visible = true
	_replay_row.visible = true
	_open_folder.visible = last_recording != ""
	_win_next.text = "Ouvrir le bac à sable" if next.get("sandbox", false) \
			else "Rejouer le premier niveau" if _next_index() == 0 else "Niveau suivant"
	_win_overlay.show()


## Niveau proposé après une victoire : l'éditeur après un essai, sinon le suivant de la liste,
## en revenant au premier plutôt que d'ouvrir l'éditeur.
func _next_index() -> int:
	if is_testing():
		return editor_index()
	var next := current + 1
	# Un défi encore fermé se saute : on passe au monde suivant.
	while next < levels.size() and is_locked(levels[next]):
		next += 1
	if next >= levels.size() or levels[next].get("editor", false) or levels[next].get("hidden", false):
		return 0
	return next


## Victoire pendant un essai depuis l'éditeur.
func _on_test_won() -> void:
	editor.proof = {"signature": LevelData.signature(levels[current]), "solution": board.layout()}
	_save_progress()
	_win_bonus.text = "Résolu ! Ton niveau peut se gagner avec %d pièce(s), en %s s.\nTu peux maintenant l'enregistrer et le partager." % [
			board.placed.size(), String.num(board.elapsed, 1).replace(".", ",")]
	board.sfx.play("win")
	_share_solution.visible = false
	_replay_row.visible = false
	_open_folder.visible = false
	_win_next.text = "Retour à l'éditeur"
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
		var extra: bool = levels[i].get("sandbox", false) or levels[i].get("custom", false) \
				or levels[i].get("hidden", false) or is_locked(levels[i])
		if not completed.has(levels[i].id) and not extra:
			return i
	return 0


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		for id: String in cfg.get_value("progress", "completed", []):
			completed[id] = true
		muted = cfg.get_value("settings", "muted", false)
		saved_layouts = cfg.get_value("layouts", "by_level", {})
		attempts = cfg.get_value("progress", "attempts", {})
		for id: String in cfg.get_value("progress", "tutorials", []):
			tutorials_done[id] = true
		bonuses = cfg.get_value("progress", "bonuses", {})
		hint_levels = cfg.get_value("progress", "hints", {})
		records = cfg.get_value("progress", "records", {})
		_editor_draft = cfg.get_value("custom", "draft", {})
		# Anciennes sauvegardes : les niveaux personnels y étaient rangés ; ils passent en fichiers.
		for level: Dictionary in cfg.get_value("custom", "levels", []):
			if not FileAccess.file_exists(_custom_path(level.id)):
				_write_custom(level)
	custom_levels = _read_custom_levels()


## Niveaux personnels lus dans `custom_dir`, dans l'ordre où ils ont été créés.
func _read_custom_levels() -> Array:
	var found: Array = []
	for file: Dictionary in LevelFile.list_dir(custom_dir):
		var level: Dictionary = file.level
		level.merge({"world": "perso", "custom": true}, true)
		found.append(level)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return [a.get("created", 0), a.id] < [b.get("created", 0), b.id])
	return found


func _custom_path(id: String) -> String:
	return custom_dir.path_join("%s.%s" % [id.validate_filename(), LevelFile.EXTENSION])


## Écrit un niveau personnel dans son fichier ; la date de création fixe sa place dans la liste.
func _write_custom(level: Dictionary) -> void:
	if not level.has("created"):
		level.created = int(Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(custom_dir)
	var error := LevelFile.save(level, _custom_path(level.id))
	if error != OK:
		push_error("Niveau personnel non enregistré (%s) : %s" % [error_string(error), level.id])


func _remove_custom(id: String) -> void:
	DirAccess.remove_absolute(_custom_path(id))


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed.keys())
	cfg.set_value("progress", "tutorials", tutorials_done.keys())
	cfg.set_value("progress", "bonuses", bonuses)
	cfg.set_value("progress", "attempts", attempts)
	cfg.set_value("progress", "hints", hint_levels)
	cfg.set_value("progress", "records", records)
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("layouts", "by_level", saved_layouts)
	if editor != null:
		var draft := {"id": editor.custom_id, "name": editor.name_edit.text,
				"goal_text": editor.goal_edit.text, "inventory": editor.inventory, "proof": editor.proof}
		draft.merge(_editor_physics())
		cfg.set_value("custom", "draft", draft)
	cfg.save(save_path)


# --- Éditeur de niveaux ---------------------------------------------------------

## Ouvre l'éditeur sur un niveau personnel : son décor revient sur le plan de travail.
func edit_level(level: Dictionary) -> void:
	load_level(editor_index())
	editor.load_from(level)
	board.set_physics(level.get("gravity", 1.0), level.get("wind", Vector2.ZERO))
	board.set_layout(level.get("fixed", []))
	_commit()
	_refresh_proof()
	_refresh_controls()
	_status.text = "Niveau « %s » ouvert dans l'éditeur." % level.name


func _toggle_goal() -> void:
	if not is_editor() or board.running:
		return
	if selected == null:
		_status.text = "Sélectionne d'abord un panier, une lampe ou un ballon."
		board.sfx.play("deny")
		return
	if not LevelData.GOAL_KINDS.has(selected.kind):
		_status.text = "Seuls un panier, une lampe ou un ballon peuvent servir d'objectif."
		board.sfx.play("deny")
		return
	var goal: bool = not selected.entry.get("goal", false)
	_edit_selected("goal", goal)
	if selected.entry.get("goal", false) == goal:
		_status.text = "Objectif du niveau." if goal else "Ce n'est plus un objectif."


## Niveau jouable tiré du plan de travail, ou message d'erreur s'il n'est pas complet.
func _editor_level(id: String) -> Variant:
	var name := editor.name_edit.text.strip_edges()
	var goal := editor.goal_edit.text.strip_edges()
	var level := LevelData.from_editor(id, name if name != "" else "Sans nom",
			goal if goal != "" else "Atteins l'objectif.", board.layout(), editor.inventory,
			board.gravity_factor(), board.wind())
	if not LevelData.has_goal(level):
		return "Il manque un objectif : sélectionne un panier, une lampe ou un ballon, puis G."
	if level.inventory.is_empty():
		return "Le joueur n'a aucune pièce : règle l'inventaire."
	return level


func _editor_try() -> void:
	if board.running:
		return
	var level: Variant = _editor_level("essai_editeur")
	if level is String:
		_status.text = level
		board.sfx.play("deny")
		return
	_save_progress()
	_test_level.clear()
	_test_level.merge(level)
	_test_level.hidden = true
	_test_level.custom = false
	histories.erase("essai_editeur")
	load_level(test_index())
	_status.text = "Essai de ton niveau. « Retour à l'éditeur » pour le retoucher."


func _editor_save() -> void:
	if board.running:
		return
	if editor.name_edit.text.strip_edges() == "":
		_status.text = "Donne un nom à ton niveau."
		board.sfx.play("deny")
		return
	var id := editor.custom_id if editor.custom_id != "" else "perso_%d" % int(Time.get_unix_time_from_system())
	var level: Variant = _editor_level(id)
	if level is String:
		_status.text = level
		board.sfx.play("deny")
		return
	level.verified = editor.is_proven(level)
	if level.verified:
		level.solution = editor.proof.solution
	var replaced := false
	for i in custom_levels.size():
		if custom_levels[i].id == id:
			level.created = custom_levels[i].get("created", 0)
			custom_levels[i] = level
			replaced = true
	if not replaced:
		custom_levels.append(level)
	_write_custom(level)
	editor.custom_id = id
	_reload_level_list(editor_index)
	board.sfx.play("place")
	_status.text = ("« %s » est enregistré dans « Mes niveaux »." % level.name) + (""
			if level.verified else " Il n'est pas encore résolu : il ne pourra pas être partagé.")


func _editor_delete() -> void:
	if board.running or editor.custom_id == "":
		return
	for i in custom_levels.size():
		if custom_levels[i].id == editor.custom_id:
			custom_levels.remove_at(i)
			break
	_remove_custom(editor.custom_id)
	completed.erase(editor.custom_id)
	bonuses.erase(editor.custom_id)
	saved_layouts.erase(editor.custom_id)
	editor.custom_id = ""
	_reload_level_list(editor_index)
	board.sfx.play("remove")
	_status.text = "Niveau supprimé. Le plan de travail reste là si tu veux le réenregistrer."


func _editor_reset() -> void:
	if board.running:
		return
	_select(null)
	editor.load_from({})
	board.set_physics(1.0, Vector2.ZERO)
	board.clear_placed()
	_commit()
	_refresh_controls()
	_status.text = "Plan de travail vide : à toi de jouer."


## Reconstruit la liste des niveaux (et l'écran de sélection) en restant sur `index_of`.
func _reload_level_list(index_of: Callable) -> void:
	var physics := [board.gravity_factor(), board.wind()]
	_assemble_levels()
	_build_level_select()
	current = index_of.call()
	board.level = levels[current]
	board.set_physics(physics[0], physics[1])
	_save_progress()
	editor.refresh()
	_refresh_level_picker()
	_refresh_controls()


# --- Niveaux du jeu dans l'éditeur ------------------------------------------------

func _open_official() -> void:
	if board.running or official_dir == "":
		return
	official_dialog.show_list(LevelFile.list_dir(official_dir))


## Ouvre un niveau du jeu dans l'éditeur. Sa solution, qui gagne (test_levels le vérifie),
## devient la preuve : il peut être réenregistré tel quel ou retouché puis réessayé.
func edit_official(path: String) -> void:
	var level := LevelFile.load_file(path)
	if level.is_empty():
		_status.text = "Fichier de niveau illisible : %s" % path.get_file()
		board.sfx.play("deny")
		return
	# Mêmes identifiants qu'en jeu pour le décor anonyme, auxquels la solution peut se référer.
	for i in level.fixed.size():
		if not level.fixed[i].has("id"):
			level.fixed[i].id = "f%d" % i
	edit_level(level)
	editor.custom_id = ""
	editor.refresh()
	var meta := {}
	for key: String in ["id", "world", "challenge", "intro", "hint", "par_time", "tutorial"]:
		if level.has(key):
			meta[key] = level[key]
	editor.source = {"path": path, "meta": meta}
	var normalized: Variant = _editor_level(level.id)
	if normalized is Dictionary and level.has("solution"):
		var solution := LevelData.remap_ids(level.solution, LevelData.decor_ids(board.layout()))
		editor.proof = {"signature": LevelData.signature(normalized), "solution": solution}
	_refresh_proof()
	_status.text = "Niveau du jeu « %s » ouvert : %s." % [level.name, path.get_file()]


func _ask_save_official() -> void:
	if board.running or official_dir == "":
		return
	var level: Variant = _editor_level("essai")
	if level is String:
		_status.text = level
		board.sfx.play("deny")
		return
	if not editor.is_proven(level):
		_status.text = "Un niveau du jeu doit avoir une solution vérifiée : gagne-le d'abord avec « Essayer »."
		board.sfx.play("deny")
		return
	var meta: Dictionary = editor.source.get("meta", {"world": "atelier"})
	if not meta.has("id"):
		meta = meta.duplicate()
		meta.id = editor.name_edit.text.strip_edges().to_lower().validate_filename().replace(" ", "_")
	official_dialog.show_form(meta, editor.source.get("path", ""))


## Écrit le niveau du plan de travail dans `levels/`, puis recharge la liste des niveaux.
func _save_official(meta: Dictionary) -> void:
	var level: Variant = _editor_level(meta.id)
	if level is String or not editor.is_proven(level):
		official_dialog.message.text = "Le niveau a changé depuis son essai : réessaie-le."
		return
	var old_path: String = editor.source.get("path", "")
	var old_id: String = editor.source.get("meta", {}).get("id", "")
	for file: Dictionary in LevelFile.list_dir(official_dir):
		if file.level.id == meta.id and file.path != old_path:
			official_dialog.message.text = "L'identifiant « %s » est déjà pris par %s." % [meta.id, file.path.get_file()]
			return
	var path := old_path
	if path == "":
		path = LevelFile.next_path(official_dir, meta.id)
	elif meta.id != old_id:
		path = old_path.get_base_dir().path_join(LevelFile.file_name(
				old_path.get_file().get_slice("_", 0).to_int(), meta))
	var official := LevelData.to_official(level, meta, editor.proof.solution)
	var error := LevelFile.save(official, path)
	if error != OK:
		official_dialog.message.text = "Écriture impossible (%s)." % error_string(error)
		return
	if path != old_path and old_path != "":
		DirAccess.remove_absolute(old_path)
	official_dialog.hide()
	editor.source = {"path": path, "meta": meta}
	LevelData.set_dir(official_dir)
	_reload_level_list(editor_index)
	board.sfx.play("place")
	_status.text = "« %s » est enregistré dans %s." % [official.name, path.get_file()]


# --- Partage --------------------------------------------------------------------

## Partage du niveau de l'éditeur : refusé tant que l'auteur ne l'a pas résolu.
func _share_level() -> void:
	if board.running:
		return
	var level: Variant = _editor_level(editor.custom_id if editor.custom_id != "" else "perso_%d" % int(Time.get_unix_time_from_system()))
	if level is String:
		_status.text = level
		board.sfx.play("deny")
		return
	if not editor.is_proven(level):
		_status.text = "Un niveau ne se partage qu'une fois résolu par son auteur : gagne-le d'abord avec « Essayer »."
		board.sfx.play("deny")
		return
	if editor.name_edit.text.strip_edges() == "":
		_status.text = "Donne un nom à ton niveau avant de le partager."
		board.sfx.play("deny")
		return
	level.solution = editor.proof.solution
	share_dialog.show_export("Partager « %s »" % level.name, Share.encode(Share.level_payload(level)), level.name)


func _share_my_solution() -> void:
	var level: Dictionary = levels[current]
	share_dialog.show_export("Ma solution de « %s »" % level.name,
			Share.encode(Share.solution_payload(level, board.layout())), "solution " + level.name)


## Import d'un code collé ou lu dans un fichier : niveau (vérifié en rejouant sa solution) ou
## solution d'un niveau existant.
func import_code(code: String) -> void:
	if verifier.busy:
		return
	var payload: Variant = Share.decode(code)
	if payload is String:
		share_dialog.message.text = payload
		return
	match payload.get("type", ""):
		"level":
			await _import_level(payload.get("level"))
		"solution":
			_import_solution(payload)
		_:
			share_dialog.message.text = "Code inconnu."


func _import_level(raw: Variant) -> void:
	share_dialog.message.text = "Vérification : la solution de l'auteur est rejouée…"
	var reason: String = await _add_shared_level(raw, "Niveau importé.")
	if reason != "":
		share_dialog.message.text = reason
		return
	share_dialog.hide()
	_status.text = "« %s » est importé dans « Mes niveaux ». À toi de le résoudre !" % levels[current].name


## Ajoute à « Mes niveaux » un niveau partagé (code importé ou galerie), une fois la solution de
## son auteur rejouée, puis l'ouvre. Renvoie la raison d'un refus, ou "" s'il est ajouté.
func _add_shared_level(raw: Variant, hint: String) -> String:
	var level: Variant = Share.clean_level(raw)
	if level is String:
		return level
	if _custom_index(level) >= 0:
		return "Ce niveau est déjà dans « Mes niveaux »."
	var reason: String = await verifier.verify(level)
	if reason != "":
		return reason
	var taken := {}
	for other: Dictionary in levels:
		taken[other.id] = true
	if taken.has(level.id) or not level.id.begins_with("perso"):
		level.id = "perso_%d" % absi(LevelData.signature(level))
	level.merge({"world": "perso", "custom": true, "verified": true, "intro": level.goal_text,
			"hint": hint}, true)
	custom_levels.append(level)
	_write_custom(level)
	_reload_level_list(func() -> int: return current)
	load_level(_index_of(level.id))
	return ""


## Place dans la liste des niveaux d'un niveau personnel identique (même décor, même inventaire,
## même physique), ou -1.
func _custom_index(level: Dictionary) -> int:
	var signature := LevelData.signature(level)
	for i in levels.size():
		if levels[i].get("custom", false) and LevelData.signature(levels[i]) == signature:
			return i
	return -1


# --- Galerie --------------------------------------------------------------------

## Galerie livrée avec le jeu, complétée par la dernière version téléchargée.
func open_gallery() -> void:
	_level_select.hide()
	gallery_entries = Gallery.merge(Gallery.load_file(Gallery.BUNDLED), Gallery.load_file(gallery_online_path))
	gallery_screen.message.text = "%d niveau(x) proposé(s) par les joueurs. « Jouer » les ajoute à « Mes niveaux »." \
			% gallery_entries.size()
	gallery_screen.open(gallery_entries, gallery_status)


## État d'un niveau de la galerie chez le joueur, avec ses essais.
func gallery_status(entry: Dictionary) -> String:
	var index := _custom_index(entry.level)
	if index < 0:
		return "À découvrir"
	var id: String = levels[index].id
	var tries: int = attempts.get(id, 0)
	if completed.has(id):
		return "Résolu en %d essai%s" % [tries, "s" if tries > 1 else ""] if tries > 0 else "Résolu"
	return "Dans Mes niveaux" + ("  ·  %d essai%s" % [tries, "s" if tries > 1 else ""] if tries > 0 else "")


func _play_gallery(entry: Dictionary) -> void:
	if verifier.busy:
		return
	var index := _custom_index(entry.level)
	if index >= 0:
		gallery_screen.hide()
		load_level(index)
		return
	gallery_screen.message.text = "Vérification de « %s » : la solution de l'auteur est rejouée…" % entry.name
	var level: Dictionary = entry.level.duplicate(true)
	level.name = entry.name
	var reason: String = await _add_shared_level(level, "Niveau de la galerie, proposé par %s." % entry.author)
	if reason != "":
		gallery_screen.message.text = reason
		return
	gallery_screen.hide()
	_status.text = "« %s » est ajouté à « Mes niveaux ». Bonne chance !" % entry.name


func _refresh_gallery() -> void:
	gallery_screen.set_busy(true)
	gallery_screen.message.text = "Téléchargement de la galerie…"
	if _gallery_http.request(gallery_url) != OK:
		_gallery_failed("la requête n'a pas pu partir")


func _on_gallery_downloaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_gallery_failed("réponse %d" % code if result == HTTPRequest.RESULT_SUCCESS else "pas de connexion")
		return
	var text := body.get_string_from_utf8()
	if Gallery.parse(text).is_empty():
		_gallery_failed("contenu illisible")
		return
	var file := FileAccess.open(gallery_online_path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()
	gallery_screen.set_busy(false)
	open_gallery()
	gallery_screen.message.text = "Galerie à jour : %d niveau(x)." % gallery_entries.size()


func _gallery_failed(why: String) -> void:
	gallery_screen.set_busy(false)
	gallery_screen.message.text = "Galerie en ligne injoignable (%s) : voici celle livrée avec le jeu." % why


## Adresse de proposition du niveau de l'éditeur, ou explication de ce qui manque.
func gallery_proposal() -> String:
	var level: Variant = _editor_level("proposition")
	if level is String:
		return "Pour proposer un niveau, ouvre-le dans l'éditeur. " + level
	if editor.name_edit.text.strip_edges() == "":
		return "Donne d'abord un nom à ton niveau dans l'éditeur."
	if not editor.is_proven(level):
		return "Gagne d'abord ton niveau avec « Essayer » : la galerie n'accepte que des niveaux résolus."
	level.solution = editor.proof.solution
	return Gallery.propose_url(level.name, Share.encode(Share.level_payload(level)))


## Un lancement de plus avant la première victoire (hors bac à sable, éditeur et essai).
func _count_attempt() -> void:
	var level: Dictionary = levels[current]
	if level.get("sandbox", false) or level.get("hidden", false) or completed.has(level.id) or replay_mode != "":
		return
	attempts[level.id] = attempts.get(level.id, 0) + 1


func _import_solution(payload: Dictionary) -> void:
	var index := -1
	for i in levels.size():
		if levels[i].id == payload.get("level_id", ""):
			index = i
	if index < 0:
		share_dialog.message.text = "Cette solution est pour un niveau que tu n'as pas."
		return
	if payload.get("signature", 0) != LevelData.signature(levels[index]):
		share_dialog.message.text = "Cette solution est pour une autre version de ce niveau."
		return
	var layout: Variant = Share.clean_layout(payload.get("layout", []))
	if layout == null:
		share_dialog.message.text = "Solution illisible."
		return
	load_level(index)
	board.clear_placed()
	var dropped := board.restore_layout(layout)
	_commit()
	share_dialog.hide()
	_status.text = "Solution chargée : lance la machine pour la voir." if dropped == 0 \
			else "Solution chargée, sauf %d pièce(s) qui n'avaient pas leur place." % dropped


# --- Relecture et enregistrement --------------------------------------------------

## Rejoue la machine gagnante depuis le début (la simulation est déterministe), en la filmant si
## `mode` vaut "gif" ou "video".
func replay(mode: String) -> void:
	if replay_mode != "":
		return
	_win_overlay.hide()
	board.stop()
	board.start()
	replay_mode = mode
	_refresh_bin()
	_refresh_controls()
	if mode != "watch":
		recorder.start(mode, Rect2i(Vector2i(board.global_position), Vector2i(Board.SIZE)))
	_status.text = "Relecture… (Espace pour l'arrêter)" if mode == "watch" \
			else "Enregistrement de la relecture… (Espace pour l'arrêter)"
	_replay_token += 1
	_finish_replay_after(Recorder.MAX_SECONDS)


func _finish_replay_after(seconds: float) -> void:
	var token := _replay_token
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if token == _replay_token:
			_finish_replay())


func _finish_replay() -> void:
	if replay_mode == "":
		return
	var mode := replay_mode
	replay_mode = ""
	_replay_token += 1
	if mode == "watch":
		_status.text = "Fin de la relecture."
	else:
		last_recording = recorder.stop()
		_status.text = "Enregistré : %s" % last_recording if last_recording != "" \
				else "L'enregistrement n'a pas pu être écrit."
	if board.has_won:
		_open_folder.visible = last_recording != ""
		_win_overlay.show()
