extends SceneTree
## Rejoue chaque niveau dans le vrai moteur physique. Vérifie qu'il ne se gagne pas seul,
## que sa solution est posable et gagne à chaque essai, quel que soit l'ordre de pose.
##
## godot --headless --path . --fixed-fps 120 -s tests/test_levels.gd
## TRACE=<id> ajoute une trace des objets mobiles de ce niveau.

const TICKS := 120
const IDLE_SECONDS := 15.0
const SOLVE_SECONDS := 30.0
const REPEATS := 8

var board: Board
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	board = Board.new()
	board.position = Vector2(0, 56)  # Même décalage que dans le jeu, sous la barre du haut.
	root.add_child(board)
	await process_frame
	_check_files()
	var only := OS.get_environment("ONLY")
	for level: Dictionary in LevelData.all():
		if only != "" and level.id != only:
			continue
		await _check(level)
	print("ÉCHECS : %d" % failures if failures else "TOUS LES NIVEAUX PASSENT")
	board.free()
	quit(1 if failures else 0)


## Les niveaux viennent des fichiers de res://levels : tous lus, identifiants uniques, mondes
## connus, et un fichier réécrit puis relu redonne exactement le même niveau.
func _check_files() -> void:
	var levels := LevelData.all()
	_report("fichiers", "18 niveaux lus", levels.size() == 18, "%d lus" % levels.size())
	var ids := {}
	for level: Dictionary in levels:
		ids[level.id] = true
		_report(level.id, "monde connu", LevelData.world(level.get("world", "")).id == level.get("world"),
				str(level.get("world")))
		var back := LevelFile.from_text(LevelFile.to_text(level))
		_report(level.id, "fichier relu à l'identique", var_to_str(back) == var_to_str(level), "différent")
	_report("fichiers", "identifiants uniques", ids.size() == levels.size(), "doublon")
	levels[0].name = "modifié"
	_report("fichiers", "chaque appel rend une copie", LevelData.all()[0].name != "modifié", "partagé")
	_report("fichiers", "texte sans niveau refusé", LevelFile.from_text("[niveau]\nname=\"sans id\"").is_empty()
			and LevelFile.from_text("[autre]\nid=\"x\"").is_empty()
			and LevelFile.from_text("n'importe quoi").is_empty(), "accepté")


func _check(level: Dictionary) -> void:
	board.load_level(level)
	board.start()
	var idle := await _simulate(IDLE_SECONDS, "")
	_report(level.id, "ne se gagne pas seul", idle < 0.0, "gagné à %.2fs" % idle)

	var solution: Array = level.solution.duplicate()
	var wins := 0
	var fastest := INF
	var slowest := 0.0
	for i in REPEATS:
		solution.reverse()  # L'ordre de pose ne doit pas compter.
		var time := await _play(level, solution)
		if time >= 0.0:
			wins += 1
			fastest = minf(fastest, time)
			slowest = maxf(slowest, time)
	_report(level.id, "solution gagnante %d/%d (%.2fs à %.2fs)" % [wins, REPEATS, fastest, slowest],
			wins == REPEATS, "pas de victoire en %ds" % SOLVE_SECONDS)
	_report(level.id, "bonus Rapide tenu par la solution (%.1fs)" % Bonus.par_time(level),
			slowest <= Bonus.par_time(level), "%.2fs" % slowest)
	_report(level.id, "bonus Économe tenu par la solution", Bonus.par_parts(level) >= solution.size(),
			"%d pièces" % solution.size())
	await _check_saved_copy(level)


## Une machine relue depuis le format de sauvegarde doit se poser entière et gagner pareil.
func _check_saved_copy(level: Dictionary) -> void:
	board.load_level(level)
	board.apply_layout(level.solution)
	var cfg := ConfigFile.new()
	cfg.set_value("layouts", "by_level", board.layout())
	var reread := ConfigFile.new()
	reread.parse(cfg.encode_to_text())
	board.load_level(level)
	var dropped := board.restore_layout(reread.get_value("layouts", "by_level"))
	_report(level.id, "sauvegarde relue entière", dropped == 0, "%d pièce(s) écartée(s)" % dropped)
	board.start()
	var time := await _simulate(SOLVE_SECONDS, "")
	_report(level.id, "sauvegarde relue gagnante", time >= 0.0, "pas de victoire")


func _play(level: Dictionary, solution: Array) -> float:
	board.load_level(level)
	for part: Part in board.apply_layout(solution):
		if board.remaining(part.kind) < 0:
			_report(level.id, "inventaire", false, "trop de %s" % part.kind)
			return -1.0
		if part.entry.pos != board.snap(part.entry.pos):
			_report(level.id, "grille", false, "%s hors grille" % part.kind)
		if not board.is_valid(part):
			_report(level.id, "pose valide", false, "%s à %s" % [part.kind, part.entry.pos])
	board.start()
	return await _simulate(SOLVE_SECONDS, level.id)


func _simulate(seconds: float, trace_id: String) -> float:
	var trace := trace_id != "" and OS.get_environment("TRACE") == trace_id
	var steps := int(seconds * TICKS)
	for i in steps:
		await physics_frame
		if board.has_won:
			return float(i) / TICKS
		if trace and i % 30 == 0:
			_trace(float(i) / TICKS)
	return -1.0


func _trace(t: float) -> void:
	var line := "t=%.2f" % t
	for part in board.parts:
		for child in part.get_children():
			if child is RigidBody2D:
				var body: RigidBody2D = child
				line += "  %s(%d,%d)" % [part.kind, body.global_position.x, body.global_position.y]
		if part.uses_channel() and part.powered:
			line += " [%s ON]" % part.kind
	print(line)


func _report(level_id: String, what: String, ok: bool, detail: String) -> void:
	if ok:
		print("ok   %s : %s" % [level_id, what])
	else:
		failures += 1
		print("KO   %s : %s (%s)" % [level_id, what, detail])
