extends "res://tests/ui_driver.gd"
## Suit les tutoriels intégrés comme un joueur, bulle après bulle, avec de vrais événements.
## godot --headless --path . --fixed-fps 120 -s tests/test_tutorial.gd


func _run() -> void:
	await _launch(true)
	await _test_first_level()
	await _test_skip_and_replay()
	await _test_cannon()
	await _test_rope_resume()
	_finish("TUTORIEL OK")


func _test_first_level() -> void:
	var board: Board = main.board
	var tuto: Tutorial = main.tutorial
	await _steps(2)
	_check("niveau 1 : tutoriel affiché", tuto.is_active() and tuto.index == 0)
	_check_bubble("étape 1")
	_check("étape 1 : le bouton Lancer est entouré", tuto.target_rect() == main._run_button.get_global_rect())

	await _click(main._run_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("lancer : étape 2", tuto.index == 1 and board.running)
	await _click(main._run_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("arrêter : étape 3", tuto.index == 2)
	_check_bubble("étape 3")

	await _drag(_bin_pos("plank"), board.to_global(Vector2(190, 240)))
	await _steps(2)
	_check("planche posée : étape 4", tuto.index == 3)
	_check_bubble("étape 4")
	await _key(KEY_R)
	await _steps(2)
	_check("un seul cran ne suffit pas", tuto.index == 3)
	await _key(KEY_R)
	await _steps(2)
	_check("deux crans : étape 5", tuto.index == 4)

	# Essai raté : la bulle propose de corriger.
	await _drag(board.to_global(Vector2(190, 240)), board.to_global(Vector2(600, 300)))
	await _key(KEY_SPACE)
	await _steps(2)
	_check("pendant la simulation : texte d'attente", tuto.current_text().begins_with("Regarde"))
	await _steps(360)
	await _key(KEY_SPACE)
	await _steps(2)
	_check("après un échec : conseil pour réessayer", tuto.current_text().begins_with("Presque"))
	_check_bubble("relance")

	await _key(KEY_Z, true)
	await _key(KEY_SPACE)
	for i in 900:
		await physics_frame
		if main._win_overlay.visible:
			break
	await _steps(2)
	_check("victoire : tutoriel terminé", not tuto.is_active() and main.tutorials_done.has("pente"))
	_check("la bulle ne couvre pas l'écran de victoire", not tuto.visible)


func _test_skip_and_replay() -> void:
	# Redémarrage : on arrive sur le niveau 2, dont le tutoriel n'a jamais été vu.
	await _restart()
	var tuto: Tutorial = main.tutorial
	await _steps(2)
	_check("redémarrage : niveau 2 et son tutoriel", main.current == 1 and tuto.is_active())
	_check("niveau 2 : présente le ressort", "ressort" in tuto.current_text())
	await _click(tuto._skip_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("Passer : bulle fermée", not tuto.is_active() and main.tutorials_done.has("rebond"))
	main.load_level(0)
	main.load_level(1)
	await _steps(2)
	_check("tutoriel passé : il ne revient pas seul", not tuto.is_active())
	var hint: Button = _button_with_text("Indice")
	await _click(hint.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("Indice : le tutoriel reprend", tuto.is_active() and tuto.index == 0)
	await _click(tuto._skip_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)


func _test_cannon() -> void:
	var board: Board = main.board
	var tuto: Tutorial = main.tutorial
	main.load_level(5)
	await _steps(2)
	_check("niveau 6 : tutoriel des canaux", tuto.is_active() and tuto.index == 0)
	_check_bubble("plaque")
	await _drag(_bin_pos("plate"), board.to_global(Vector2(120, 620)))
	await _drag(_bin_pos("cannon"), board.to_global(Vector2(360, 520)))
	await _steps(2)
	_check("étape d'explication : bouton Compris", tuto.index == 2 and tuto._ok_button.visible)
	_check_bubble("explication")
	await _click(tuto._ok_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("Compris : étape suivante", tuto.index == 3 and not tuto._ok_button.visible)
	await _click(board.to_global(Vector2(360, 520)), MOUSE_BUTTON_LEFT)
	for i in 3:
		await _button(board.to_global(Vector2(360, 520)), MOUSE_BUTTON_WHEEL_UP, true)
	await _steps(2)
	_check("molette vers le haut : canon pointé vers le haut", board.placed[1].rot == 315.0 and tuto.index == 4)
	await _key(KEY_SPACE)
	for i in 900:
		await physics_frame
		if main._win_overlay.visible:
			break
	_check("niveau 6 gagné en suivant le tutoriel", main._win_overlay.visible and not tuto.is_active())


func _test_rope_resume() -> void:
	var board: Board = main.board
	var tuto: Tutorial = main.tutorial
	main.load_level(6)
	await _steps(2)
	_check_bubble("poulies")
	await _drag(_bin_pos("pulley"), board.to_global(Vector2(300, 40)))
	await _drag(_bin_pos("pulley"), board.to_global(Vector2(700, 40)))
	# On s'en va puis on revient : les étapes déjà faites sont sautées.
	main.load_level(0)
	main.load_level(6)
	await _steps(2)
	_check("retour au niveau : reprise à la corde", tuto.is_active() and tuto.index == 1)
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("corde en main : le boulet est désigné", tuto.index == 2 \
			and tuto.target_rect().has_point(board.to_global(Vector2(700, 120))))
	_check_bubble("boulet")
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("boulet choisi : la bille est désignée", tuto.index == 3)
	_check_bubble("bille")
	await _click(board.to_global(Vector2(700, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 610)), MOUSE_BUTTON_LEFT)
	await _steps(2)
	_check("corde posée : dernière étape", tuto.index == 4)
	await _key(KEY_SPACE)
	for i in 900:
		await physics_frame
		if main._win_overlay.visible:
			break
	_check("Contrepoids gagné en suivant le tutoriel", main._win_overlay.visible and not tuto.is_active())


## La bulle reste à l'écran et ne cache ni sa cible ni la zone indiquée.
func _check_bubble(what: String) -> void:
	var tuto: Tutorial = main.tutorial
	var bubble := tuto.bubble_rect()
	var screen := Rect2(Vector2.ZERO, Vector2(1280, 720))
	var target := tuto.target_rect()
	var zone: Rect2 = main._tutorial_target(tuto.steps[tuto.index].get("zone", ""))
	_check("%s : bulle à l'écran" % what, screen.encloses(bubble))
	_check("%s : bulle à côté de sa cible" % what, not bubble.intersects(target) and not bubble.intersects(zone))
	var hidden := 0.0
	for obstacle: Rect2 in main._tutorial_obstacles():
		hidden += bubble.intersection(obstacle).get_area()
	_check("%s : bulle sans pièce ni bouton dessous (%d px²)" % [what, hidden], hidden == 0.0)


func _button_with_text(text: String) -> Button:
	for node in main.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node
	return null
