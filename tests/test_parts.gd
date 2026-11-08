extends "res://tests/board_driver.gd"
## Comportement des pièces mécaniques, mesuré en vraie simulation.
## godot --headless --path . --fixed-fps 120 -s tests/test_parts.gd


func _run() -> void:
	await _start_board()
	await _test_switch()
	await _test_timer()
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
