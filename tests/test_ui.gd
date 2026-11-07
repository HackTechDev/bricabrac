extends SceneTree
## Joue comme un humain : événements souris et clavier réels, du bac au panier.
## godot --headless --path . --fixed-fps 120 -s tests/test_ui.gd

const SAVE := "user://test_ui_progress.cfg"

var main: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)  # La fenêtre headless fait 64x64 par défaut.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.save_path = SAVE
	root.add_child(main)
	await process_frame
	await process_frame
	var board: Board = main.board
	_check("démarre au niveau 1", main.current == 0)

	# Glisser une planche du bac sur une zone occupée : retour au bac.
	var bin_pos: Vector2 = main._items[0].get_global_rect().get_center()
	await _drag(bin_pos, board.to_global(Vector2(150, 60)))
	_check("pose refusée sur un objet", board.placed.is_empty() and board.remaining("plank") == 2)

	# Pose valide puis rotation au clavier.
	await _drag(bin_pos, board.to_global(Vector2(600, 200)))
	_check("pose acceptée", board.placed.size() == 1 and board.remaining("plank") == 1)
	await _key(KEY_R)
	await _key(KEY_R)
	_check("rotation 2 x 15°", is_equal_approx(board.placed[0].rot, 30.0))

	# Déplacement d'une pièce posée, jusqu'à la position gagnante.
	await _drag(board.to_global(Vector2(600, 200)), board.to_global(Vector2(190, 240)))
	_check("déplacement + grille", board.placed[0].pos == Vector2(190, 240))

	# Clic droit : retirer ; puis on repose.
	await _click(board.to_global(Vector2(190, 240)), MOUSE_BUTTON_RIGHT)
	_check("clic droit retire", board.placed.is_empty())
	await _drag(bin_pos, board.to_global(Vector2(190, 240)))
	await _key(KEY_R)
	await _key(KEY_R)

	# Lancer à l'espace, arrêter, rien n'a bougé dans la disposition.
	await _key(KEY_SPACE)
	_check("simulation lancée", board.running)
	await _steps(120)
	await _key(KEY_SPACE)
	_check("arrêt : retour à l'atelier", not board.running and board.placed.size() == 1)
	var ball := board.parts[0]
	_check("arrêt : objets replacés", ball.get_child(0).global_position.is_equal_approx(board.to_global(Vector2(150, 60))))

	# Lancer jusqu'à la victoire, passer au niveau suivant par le bouton.
	await _click(main._run_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	for i in 1200:
		await physics_frame
		if main._win_overlay.visible:
			break
	_check("écran de victoire", main._win_overlay.visible)
	await _steps(2)
	await _click(main._win_next.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("niveau suivant", main.current == 1 and not board.running)
	_check("progression enregistrée", FileAccess.file_exists(SAVE))

	# Pièces à canal : plaque sur 1, ventilateur sur 0 (toujours en marche).
	main.load_level(5)
	await _steps(2)
	var plate := board.place("plate", Vector2(120, 620))
	_check("plaque : canal 1 par défaut", plate.channel == 1 and not plate.powered)
	main._select(plate)
	await _key(KEY_C)
	_check("touche C : canal 2", board.placed[0].channel == 2)
	main.load_level(3)
	await _steps(2)
	var fan := board.place("fan", Vector2(100, 400))
	_check("ventilateur : canal 0 par défaut", fan.channel == 0 and fan.powered)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("ÉCHECS : %d" % failures if failures else "INTERFACE OK")
	main.free()
	quit(1 if failures else 0)


func _drag(from: Vector2, to: Vector2) -> void:
	await _move(from)
	await _button(from, MOUSE_BUTTON_LEFT, true)
	await _move((from + to) / 2.0)
	await _move(to)
	await _button(to, MOUSE_BUTTON_LEFT, false)


func _click(at: Vector2, button: MouseButton) -> void:
	await _move(at)
	await _button(at, button, true)
	await _button(at, button, false)


func _move(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	root.push_input(ev)
	await process_frame


func _button(at: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = at
	ev.global_position = at
	ev.button_index = button
	ev.pressed = pressed
	root.push_input(ev)
	await process_frame


func _key(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = true
	root.push_input(ev)
	await process_frame


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "KO   ") + what)
	if not ok:
		failures += 1
