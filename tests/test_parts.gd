extends "res://tests/board_driver.gd"
## Comportement des pièces mécaniques, mesuré en vraie simulation.
## godot --headless --path . --fixed-fps 120 -s tests/test_parts.gd


func _run() -> void:
	await _start_board()
	await _test_switch()
	await _test_timer()
	await _test_gates()
	await _test_scissors()
	await _test_magnet()
	await _test_gears()
	_end("PIÈCES OK")


## La lampe s'allume au délai près (une image de physique), et pas avant.
func _test_timer() -> void:
	_level([
		{"kind": "timer", "pos": Vector2(300, 600), "channel": 2, "delay": 1.5},
		{"kind": "lamp", "pos": Vector2(900, 600), "channel": 2},
	])
	board.start()
	var lit_at := -1
	for i in 300:
		await physics_frame
		if lit_at < 0 and _lamp().powered:
			lit_at = i + 1
	_check("minuterie : lampe allumée à 1,5 s (%d images)" % lit_at, absi(lit_at - 180) <= 1)
	_level([{"kind": "timer", "pos": Vector2(300, 600), "channel": 1}])
	_check("minuterie : délai par défaut 2 s", (board.parts[0] as TimerPart).delay() == 2.0)


## Une trappe lâche la bille à l'ouverture ; une porte la retient puis la laisse passer.
func _test_gates() -> void:
	_level([
		{"kind": "trapdoor", "id": "trappe", "pos": Vector2(240, 300), "channel": 1},
		{"kind": "ball", "id": "b", "pos": Vector2(300, 270)},
		{"kind": "timer", "pos": Vector2(800, 600), "channel": 1, "delay": 1.0},
	])
	board.start()
	await _steps(110)
	_check("trappe fermée : la bille repose dessus", absf(_pos("b").y - 278.0) < 4.0)
	await _steps(100)
	_check("trappe ouverte : la bille est tombée", _pos("b").y > 400.0)
	var gate := board.find_part("trappe") as GatePart
	_near("trappe : panneau à la verticale", gate.panel.rotation_degrees, 90.0, 0.01)

	_level([
		{"kind": "conveyor", "pos": Vector2(300, 600)},
		{"kind": "ball", "id": "b", "pos": Vector2(240, 570)},
		{"kind": "door", "pos": Vector2(460, 470), "channel": 1},
		{"kind": "timer", "pos": Vector2(800, 400), "channel": 1, "delay": 2.0},
	])
	board.start()
	await _steps(220)
	_check("porte fermée : la bille est bloquée", _pos("b").x < 460.0)
	await _steps(240)
	_check("porte ouverte : la bille est passée", _pos("b").x > 480.0)


## Bille suspendue à une poutre ; les ciseaux coupent la corde à 1 s, et seulement celle-là.
func _test_scissors() -> void:
	_level([
		{"kind": "plank", "id": "poutre", "pos": Vector2(500, 60), "len": 300.0, "locked": true},
		{"kind": "ball", "id": "b", "pos": Vector2(400, 300)},
		{"kind": "ball", "id": "autre", "pos": Vector2(600, 300)},
		{"kind": "rope", "from": "b", "to": "poutre", "to_off": Vector2(-100, 0)},
		{"kind": "rope", "from": "autre", "to": "poutre", "to_off": Vector2(100, 0)},
		{"kind": "scissors", "pos": Vector2(400, 200), "channel": 1},
		{"kind": "timer", "pos": Vector2(900, 600), "channel": 1, "delay": 1.0},
	])
	board.start()
	await _steps(110)
	_check("ciseaux : la bille reste suspendue avant le délai", absf(_pos("b").y - 300.0) < 3.0)
	await _steps(60)
	_check("ciseaux : corde coupée, la bille tombe", _pos("b").y > 360.0)
	_check("ciseaux : l'autre corde tient", absf(_pos("autre").y - 300.0) < 3.0)
	var cut := 0
	for part in board.parts:
		if part is RopePart and (part as RopePart).is_cut():
			cut += 1
	_check("ciseaux : une seule corde coupée", cut == 1)


## Boulet et caisse posés à même distance d'un aimant : seul le boulet est attiré, et seulement
## une fois l'aimant allumé.
func _test_magnet() -> void:
	_level([
		{"kind": "magnet", "pos": Vector2(500, 618), "rot": 90.0, "channel": 1},
		{"kind": "ball_heavy", "id": "boulet", "pos": Vector2(680, 618)},
		{"kind": "crate", "id": "caisse", "pos": Vector2(320, 618)},
		{"kind": "ball_bouncy", "id": "caoutchouc", "pos": Vector2(500, 400)},
		{"kind": "timer", "pos": Vector2(900, 400), "channel": 1, "delay": 1.0},
	])
	board.start()
	await _steps(110)
	_check("aimant éteint : le boulet ne bouge pas", absf(_pos("boulet").x - 680.0) < 2.0)
	await _steps(240)
	_check("aimant allumé : le boulet vient se coller (%d)" % _pos("boulet").x, _pos("boulet").x < 560.0)
	_check("aimant : la caisse ne bouge pas", absf(_pos("caisse").x - 320.0) < 2.0)
	_check("aimant : le caoutchouc n'est pas attiré", absf(_pos("caoutchouc").x - 500.0) < 2.0)


func _spin(id: String) -> float:
	return _rigid(id).angular_velocity


## Moteur → roue A → roue B : sens alternés, vitesses dans le rapport des rayons ; une roue trop
## loin ne tourne pas ; le bras de la dernière roue renverse un domino.
func _test_gears() -> void:
	var m := GearPart.MOTOR_SPEED
	_level([
		{"kind": "motor", "id": "moteur", "pos": Vector2(300, 300), "channel": 1},
		{"kind": "gear", "id": "a", "pos": Vector2(370, 300), "rot": 270.0},
		{"kind": "gear", "id": "b", "pos": Vector2(450, 300), "rot": 270.0},
		{"kind": "gear", "id": "seule", "pos": Vector2(700, 300)},
		{"kind": "domino", "id": "d", "pos": Vector2(535, 300)},
		{"kind": "plank", "pos": Vector2(565, 337), "len": 60.0},
		{"kind": "timer", "pos": Vector2(900, 600), "channel": 1, "delay": 0.5},
	])
	_check("engrenages : le moteur touche une roue", board.gear_neighbors(board.find_part("moteur")).size() == 1)
	_check("engrenages : la roue isolée ne touche rien", board.gear_neighbors(board.find_part("seule")).is_empty())
	board.start()
	await _steps(50)
	_check("moteur éteint : rien ne tourne", absf(_spin("a")) < 0.01)
	await _steps(30)
	_near("moteur allumé : vitesse imposée", _spin("moteur"), m, 0.02)
	_near("roue A : sens inverse, rapport 30/40", _spin("a"), -m * 30.0 / 40.0, 0.03)
	_near("roue B : même sens que le moteur", _spin("b"), m * 30.0 / 40.0, 0.03)
	_check("roue isolée immobile", absf(_spin("seule")) < 0.01)
	await _steps(240)
	_check("le bras renverse le domino", absf(_rigid("d").rotation_degrees) > 45.0)


func _lamp() -> LampPart:
	for part in board.parts:
		if part is LampPart:
			return part
	return null


## Deux billes passent l'une après l'autre sur l'interrupteur : allumé, puis éteint.
func _test_switch() -> void:
	_level([
		{"kind": "switch", "pos": Vector2(300, 600), "channel": 1},
		{"kind": "ball", "pos": Vector2(300, 400)},
		{"kind": "ball", "pos": Vector2(300, 100)},
		{"kind": "lamp", "pos": Vector2(900, 600), "channel": 1},
		{"kind": "conveyor", "pos": Vector2(600, 500), "channel": 1},
	])
	board.start()
	# Premier choc vers 0,54 s, second vers 0,95 s (chute libre jusqu'au levier).
	await _steps(50)
	_check("interrupteur : rien avant le premier choc", not _lamp().powered)
	await _steps(40)
	_check("interrupteur : premier choc, lampe allumée", _lamp().powered and board.channel_on[1])
	var conveyor := board.parts[4] as ConveyorPart
	_check("interrupteur : le tapis démarre", conveyor.body.constant_linear_velocity.length() > 100.0)
	await _steps(60)
	_check("interrupteur : second choc, lampe éteinte", not _lamp().powered and not board.channel_on[1])
	_check("interrupteur : le tapis s'arrête", conveyor.body.constant_linear_velocity == Vector2.ZERO)

	# Une plaque rallume ce qu'un interrupteur a éteint.
	_level([
		{"kind": "switch", "pos": Vector2(300, 600), "channel": 1},
		{"kind": "ball", "pos": Vector2(300, 400)},
		{"kind": "ball", "pos": Vector2(300, 100)},
		{"kind": "plate", "pos": Vector2(700, 626), "channel": 1},
		{"kind": "ball", "pos": Vector2(700, 20)},
		{"kind": "lamp", "pos": Vector2(900, 600), "channel": 1},
	])
	board.start()
	await _steps(125)
	_check("plaque après interrupteur : d'abord éteinte", not _lamp().powered)
	await _steps(40)
	_check("plaque après interrupteur : lampe rallumée", _lamp().powered)
	board.stop()
	_check("arrêt : canaux remis à zéro", not board.channel_on[1])
