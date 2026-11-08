extends "res://tests/ui_driver.gd"
## Joue comme un humain : événements souris et clavier réels, du bac au panier.
## godot --headless --path . --fixed-fps 120 -s tests/test_ui.gd


func _run() -> void:
	# Les bulles du tutoriel sont testées à part, dans test_tutorial.gd.
	await _launch(false)
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

	await _test_rope_tool()
	await _test_sound_toggle()
	await _test_board_tooltips()
	await _test_timer_setting()
	await _test_undo()
	await _test_persistence()
	await _test_undo_cascade()
	await _test_stale_save()

	_finish("INTERFACE OK")


## Pose complète d'une corde à la souris, sur le niveau Contrepoids.
func _test_rope_tool() -> void:
	var board: Board = main.board
	main.load_level(6)
	await _steps(2)
	var pulley_pos := _bin_pos("pulley")
	await _drag(pulley_pos, board.to_global(Vector2(300, 40)))
	pulley_pos = _bin_pos("pulley")
	await _drag(pulley_pos, board.to_global(Vector2(700, 40)))
	_check("deux poulies posées", board.remaining("pulley") == 0)

	# Annulation : clic droit pendant la pose.
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	_check("outil corde actif", main.rope_tool)
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_RIGHT)
	_check("clic droit annule la corde", not main.rope_tool and board.remaining("rope") == 1)

	# Refus : commencer sur une poulie.
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 40)), MOUSE_BUTTON_LEFT)
	_check("refus : commencer sur une poulie", main.rope_tool and main.rope_from == null)

	# Pose : boulet, poulie droite, poulie gauche, bille.
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 610)), MOUSE_BUTTON_LEFT)
	_check("corde posée", not main.rope_tool and board.remaining("rope") == 0)

	# La disposition faite à la souris doit gagner, comme la solution de référence.
	await _key(KEY_SPACE)
	for i in 1800:
		await physics_frame
		if main._win_overlay.visible:
			break
	_check("Contrepoids gagné à la souris", main._win_overlay.visible)
	main.toggle_run()
	await _steps(2)

	# Un clic sur la corde la sélectionne sans la déplacer ; clic droit : retour au bac.
	await _click(board.to_global(Vector2(500, 40)), MOUSE_BUTTON_LEFT)
	_check("clic sur la corde : sélection", main.selected is RopePart and main.drag_part == null)
	await _click(board.to_global(Vector2(500, 40)), MOUSE_BUTTON_RIGHT)
	_check("clic droit retire la corde", board.remaining("rope") == 1)

	# Retirer une poulie emporte la corde qui y passe.
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 610)), MOUSE_BUTTON_LEFT)
	_check("corde reposée", board.remaining("rope") == 0)
	await _click(board.to_global(Vector2(700, 40)), MOUSE_BUTTON_RIGHT)
	_check("poulie retirée : corde au bac", board.remaining("rope") == 1 and board.remaining("pulley") == 1)

	# Attache à une pièce de décor qui n'a pas d'identifiant dans le niveau (la plaque).
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 180)), MOUSE_BUTTON_LEFT)
	_check("corde vers une pièce de décor", board.remaining("rope") == 0)
	var rope: RopePart = board.parts.back()
	_check("corde vers le décor : tracé valide", rope.points().size() == 2)


## R et la molette règlent le délai d'une minuterie au lieu de la faire pivoter.
func _test_timer_setting() -> void:
	var board: Board = main.board
	main.load_level(0)
	await _steps(2)
	var timer := board.place("timer", Vector2(600, 300))
	main._select(timer)
	_check("minuterie : bouton Délai", main._ctx_buttons.rotate.text == "Délai (R)" \
			and not main._ctx_buttons.rotate.disabled)
	await _key(KEY_R)
	_check("R : délai 2,5 s", main.selected.entry.delay == 2.5 and main.selected.entry.get("rot", 0.0) == 0.0)
	await _key(KEY_R, false, true)
	await _key(KEY_R, false, true)
	_check("Maj+R : délai 1,5 s", main.selected.entry.delay == 1.5)
	for i in 10:
		await _button(board.to_global(Vector2(600, 300)), MOUSE_BUTTON_WHEEL_UP, true)
	_check("délai minimal 0,5 s", main.selected.entry.delay == 0.5)
	board.remove(main.selected)
	main._select(null)


## Survoler une pièce du plateau affiche son infobulle, avec ses réglages.
func _test_board_tooltips() -> void:
	var board: Board = main.board
	main.load_level(5)
	await _steps(2)
	board.clear_placed()  # Une plaque restaurée d'un test précédent serait sur un autre canal.
	await _drag(_bin_pos("plate"), board.to_global(Vector2(120, 620)))
	await _move(board.to_global(Vector2(500, 300)))
	await _move(board.to_global(Vector2(120, 620)))
	await _steps(20)
	_check("survol bref : pas encore d'infobulle", not main._tooltip.visible)
	await _steps(60)
	var text: String = main._tooltip_label.text
	_check("infobulle d'une pièce posée", main._tooltip.visible and text.begins_with("Plaque") and "Canal 1" in text)
	_check("infobulle à l'écran", Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(main._tooltip.get_global_rect()))
	await _move(board.to_global(Vector2(800, 507)))  # Fond du panier.
	await _steps(80)
	_check("infobulle d'une pièce du décor", "décor" in main._tooltip_label.text \
			and main._tooltip_label.text.begins_with("Panier"))
	await _move(board.to_global(Vector2(500, 300)))
	_check("hors pièce : infobulle fermée", not main._tooltip.visible)
	await _move(board.to_global(Vector2(120, 620)))
	await _steps(80)
	await _button(board.to_global(Vector2(120, 620)), MOUSE_BUTTON_LEFT, true)
	_check("clic : infobulle fermée", not main._tooltip.visible)
	await _button(board.to_global(Vector2(120, 620)), MOUSE_BUTTON_LEFT, false)
	main.board.clear_placed()


## Le niveau Par-dessus le mur, vide au départ : ressort et planche.
func _test_undo() -> void:
	var board: Board = main.board
	main.load_level(1)
	await _steps(2)
	_check("rien à annuler au départ", main._ctx_buttons.undo.disabled)
	await _key(KEY_Z, true)
	_check("Ctrl+Z sans historique : sans effet", board.placed.is_empty())

	await _drag(_bin_pos("spring"), board.to_global(Vector2(200, 500)))
	await _key(KEY_R)
	await _drag(board.to_global(Vector2(200, 500)), board.to_global(Vector2(300, 400)))
	_check("trois actions faites", board.placed[0].pos == Vector2(300, 400) and board.placed[0].rot == 15.0)

	# Un glisser sur place ne crée pas d'étape.
	await _drag(board.to_global(Vector2(300, 400)), board.to_global(Vector2(300, 400)))
	await _key(KEY_Z, true)
	_check("Ctrl+Z : déplacement annulé d'un coup", board.placed[0].pos == Vector2(200, 500))
	_check("la rotation reste", board.placed[0].rot == 15.0)
	await _key(KEY_Z, true)
	_check("Ctrl+Z : rotation annulée", board.placed[0].rot == 0.0)
	await _key(KEY_Z, true)
	_check("Ctrl+Z : pose annulée, pièce au bac", board.placed.is_empty() and board.remaining("spring") == 1)
	_check("objet affiché retiré", board.part_at(Vector2(200, 500)) == null)

	await _key(KEY_Y, true)
	await _key(KEY_Z, true, true)
	await _key(KEY_Y, true)
	_check("Ctrl+Y et Ctrl+Maj+Z rétablissent", board.placed[0].pos == Vector2(300, 400))
	_check("pièce rétablie déplaçable", board.part_at(Vector2(300, 400)) != null)
	await _key(KEY_Y, true)
	_check("rien de plus à rétablir", main._ctx_buttons.redo.disabled)

	# Une nouvelle action efface ce qui pouvait être rétabli.
	await _key(KEY_Z, true)
	await _key(KEY_F)  # Sans effet sur un ressort : pas d'étape.
	_check("action sans effet : on peut encore rétablir", not main._ctx_buttons.redo.disabled)
	await _click(board.to_global(Vector2(200, 500)), MOUSE_BUTTON_LEFT)
	await _key(KEY_R)
	_check("nouvelle action : plus de rétablissement", main._ctx_buttons.redo.disabled)

	# Tout retirer s'annule en une fois.
	await _drag(_bin_pos("plank"), board.to_global(Vector2(700, 200)))
	await _click(main._clear_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("tout retirer", board.placed.is_empty())
	await _click(main._ctx_buttons.undo.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("bouton Annuler : deux pièces reviennent", board.placed.size() == 2)

	# Pas d'annulation pendant la simulation.
	var before: Array = board.layout()
	await _key(KEY_SPACE)
	await _key(KEY_Z, true)
	_check("Ctrl+Z ignoré pendant la simulation", board.running and board.layout() == before)
	_check("boutons grisés pendant la simulation", main._ctx_buttons.undo.disabled)
	await _key(KEY_SPACE)
	_check("lancer ne crée pas d'étape", board.layout() == before)
	await _drag(board.to_global(Vector2(700, 200)), board.to_global(Vector2(700, 300)))
	await _key(KEY_Z, true)
	_check("lancer n'a pas perturbé l'historique", board.layout() == before)

	# Pendant la pose d'une corde, Ctrl+Z abandonne la pose.
	main.load_level(7)
	await _steps(2)
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(120, 300)), MOUSE_BUTTON_LEFT)
	await _key(KEY_Z, true)
	_check("Ctrl+Z annule la corde en cours", not main.rope_tool and board.placed.is_empty())

	# Chaque niveau garde son propre historique.
	main.load_level(1)
	await _steps(2)
	_check("historique conservé par niveau", not main._ctx_buttons.undo.disabled)


## Pendule : corde vers la poutre ; Contrepoids : corde vers la plaque, qui n'a pas d'id dans le niveau.
func _test_persistence() -> void:
	var board: Board = main.board
	main.load_level(1)
	await _steps(2)
	var layout_before: Array = board.layout()
	_check("machine présente avant de changer de niveau", not layout_before.is_empty())
	main.load_level(0)
	await _steps(2)
	main.load_level(1)
	await _steps(2)
	_check("changer de niveau conserve les pièces", board.layout() == layout_before)

	main.load_level(6)
	await _steps(2)
	var rope_layout: Array = board.layout()
	_check("corde vers le décor en place", board.remaining("rope") == 0)

	# Redémarrage complet : nouvelle interface, relecture du fichier.
	await _restart()
	board = main.board
	main.load_level(1)
	await _steps(2)
	_check("redémarrage : pièces restaurées", board.layout() == layout_before)
	_check("redémarrage : pas d'annulation d'avant", main._ctx_buttons.undo.disabled)
	var spring := board.part_at(layout_before[0].pos)
	_check("redémarrage : pièce restaurée sélectionnable", spring != null)

	main.load_level(6)
	await _steps(2)
	_check("redémarrage : corde restaurée", board.layout() == rope_layout)
	var rope: RopePart
	for part in board.parts:
		if part is RopePart:
			rope = part
	_check("redémarrage : corde rattachée au décor", rope != null and rope.points().size() == 2)

	# Une nouvelle pièce ne doit pas reprendre l'identifiant d'une pièce restaurée.
	main.load_level(1)
	await _steps(2)
	var ids: Array = []
	for entry: Dictionary in board.placed:
		ids.append(entry.id)
	var extra := board.place("plank", Vector2(800, 100))
	_check("nouvel identifiant sans collision", not ids.has(extra.entry.id))
	board.remove(extra)


## Retirer une poulie emporte sa corde : un seul Ctrl+Z doit ramener les deux.
func _test_undo_cascade() -> void:
	var board: Board = main.board
	main.load_level(6)
	await _steps(2)
	await _click(board.to_global(Vector2(500, 150)), MOUSE_BUTTON_RIGHT)
	_check("corde vers le décor retirée", board.remaining("rope") == 1)
	await _click(_bin_pos("rope"), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(700, 120)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 40)), MOUSE_BUTTON_LEFT)
	await _click(board.to_global(Vector2(300, 610)), MOUSE_BUTTON_LEFT)
	_check("corde passant par la poulie posée", board.remaining("rope") == 0)
	await _click(board.to_global(Vector2(300, 40)), MOUSE_BUTTON_RIGHT)
	_check("poulie retirée avec sa corde", board.remaining("rope") == 1 and board.remaining("pulley") == 2)
	await _key(KEY_Z, true)
	_check("Ctrl+Z : poulie et corde reviennent", board.remaining("rope") == 0 and board.remaining("pulley") == 1)
	var rope: RopePart
	for part in board.parts:
		if part is RopePart:
			rope = part
	_check("Ctrl+Z : corde rattachée à la poulie", rope != null and rope.points().size() == 3)


## Sauvegarde devenue incohérente : le niveau démarre quand même, sans les pièces invalides.
func _test_stale_save() -> void:
	main.saved_layouts["pente"] = [
		{"kind": "plank", "pos": Vector2(190, 240), "rot": 30.0, "dir": 1, "id": "p1"},
		{"kind": "plank", "pos": Vector2(600, 200), "rot": 0.0, "dir": 1, "id": "p2"},
		{"kind": "plank", "pos": Vector2(800, 200), "rot": 0.0, "dir": 1, "id": "p3"},
		{"kind": "piece_disparue", "pos": Vector2(10, 10)},
		{"kind": "plank", "pos": "pas une position"},
		{"kind": "rope", "from": "absent", "to": "p1"},
		"pas une entrée",
	]
	main.levels[0].inventory = {"plank": 2, "rope": 1}
	main.histories.erase("pente")
	main.load_level(0)
	await _steps(2)
	_check("sauvegarde incohérente : seules les pièces valides restent", main.board.placed.size() == 2)
	main.levels[0].inventory = {"plank": 2}
	main.saved_layouts["pente"] = [
		{"kind": "plank", "pos": Vector2(150, 60), "rot": 0.0, "dir": 1, "id": "p1"},
	]
	main.histories.erase("pente")
	main.load_level(0)
	await _steps(2)
	_check("sauvegarde incohérente : pièce sur le décor écartée", main.board.placed.is_empty())


func _test_sound_toggle() -> void:
	var was_muted: bool = main.muted
	await _key(KEY_M)
	_check("touche M : son coupé", main.muted != was_muted and AudioServer.is_bus_mute(0) == main.muted)
	await _click(main._sound_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	_check("bouton Son : rétabli", main.muted == was_muted)
