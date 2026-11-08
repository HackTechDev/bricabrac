extends SceneTree
## Aides partagées par les tests du plateau seul (sans interface) : construire un petit niveau,
## faire avancer la physique et comparer des mesures aux valeurs attendues.

const G := 980.0

var board: Board
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	pass


func _start_board() -> void:
	board = Board.new()
	board.position = Vector2(0, 56)  # Même décalage que dans le jeu, sous la barre du haut.
	root.add_child(board)
	await process_frame


func _end(success: String) -> void:
	print("ÉCHECS : %d" % failures if failures else success)
	board.free()
	# Les sons arrêtés ne quittent le serveur audio qu'à son prochain mixage, en temps réel : sans
	# cette pause, ils seraient comptés comme des fuites (« ObjectDB instances leaked »).
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(1 if failures else 0)


func _level(fixed: Array, inventory := {}, extra := {}) -> void:
	var level := {"fixed": fixed, "inventory": inventory}
	level.merge(extra)
	board.load_level(level)


func _rigid(id: String) -> RigidBody2D:
	return board.find_part(id).main_body as RigidBody2D


## Position sur le plateau, comparable aux valeurs de la disposition.
func _pos(id: String) -> Vector2:
	return board.to_local(_rigid(id).global_position)


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _near(what: String, value: float, expected: float, tolerance: float) -> void:
	var ok := absf(value - expected) <= absf(expected) * tolerance
	_check("%s : %.1f (attendu %.1f)" % [what, value, expected], ok)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "KO   ") + what)
	if not ok:
		failures += 1
