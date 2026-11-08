extends "res://tests/board_driver.gd"
## Physique de la corde et sons : mesures comparées aux valeurs attendues.
## godot --headless --path . --fixed-fps 120 -s tests/test_rope.gd


func _run() -> void:
	await _start_board()
	await _test_atwood()
	await _test_equal_masses()
	await _test_pendulum()
	await _test_only_pulls()
	await _test_slack()
	await _test_balloon_cut()
	_test_cascade()
	_test_sound_bank()
	await _test_sound_events()
	_end("CORDE ET SON OK")


func _pulleys() -> Array:
	return [
		{"kind": "pulley", "id": "w1", "pos": Vector2(300, 40)},
		{"kind": "pulley", "id": "w2", "pos": Vector2(700, 40)},
	]


func _rope() -> RopePart:
	for part in board.parts:
		if part is RopePart:
			return part
	return null


## Machine d'Atwood : a = g (m1 - m2) / (m1 + m2).
func _test_atwood() -> void:
	_level(_pulleys() + [
		{"kind": "ball_heavy", "id": "lourd", "pos": Vector2(700, 150)},
		{"kind": "ball", "id": "leger", "pos": Vector2(300, 500)},
		{"kind": "rope", "from": "lourd", "via": ["w2", "w1"], "to": "leger"},
	])
	board.start()
	var y0 := _pos("lourd").y
	var yb0 := _pos("leger").y
	var t := 0.5
	await _steps(int(t * 120))
	var fall := _pos("lourd").y - y0
	var rise := yb0 - _pos("leger").y
	var expected := 0.5 * G * (6.0 - 1.5) / 7.5 * t * t
	_near("Atwood : chute du lourd", fall, expected, 0.06)
	_near("Atwood : la montée égale la chute", rise, fall, 0.02)
	_check("corde non étirée (%.2f px)" % _rope().max_stretch, _rope().max_stretch < 2.0)


func _test_equal_masses() -> void:
	_level(_pulleys() + [
		{"kind": "ball", "id": "a", "pos": Vector2(700, 300)},
		{"kind": "ball", "id": "b", "pos": Vector2(300, 300)},
		{"kind": "rope", "from": "a", "via": ["w2", "w1"], "to": "b"},
	])
	board.start()
	await _steps(120)
	_near("masses égales : équilibre", _pos("a").y, 300.0, 0.01)


func _test_pendulum() -> void:
	var anchor := {"kind": "plank", "id": "poutre", "pos": Vector2(500, 60), "len": 100.0, "locked": true}
	_level([
		anchor,
		{"kind": "ball_heavy", "id": "m", "pos": Vector2(200, 60 + 40)},
		{"kind": "rope", "from": "m", "to": "poutre"},
	])
	board.start()
	var radius := _rope().rest_length
	var lowest := 0.0
	var farthest := 0.0
	for i in 480:
		await physics_frame
		var pos := _pos("m")
		lowest = maxf(lowest, pos.y)
		farthest = maxf(farthest, pos.distance_to(Vector2(500, 60)))
	_near("pendule : rayon conservé", farthest, radius, 0.01)
	_near("pendule : passe au point bas", lowest, 60.0 + radius, 0.04)


## Une bille lancée vers l'attache : la corde se détend au lieu de la repousser.
func _test_only_pulls() -> void:
	_level([
		{"kind": "plank", "id": "p", "pos": Vector2(500, 100), "len": 100.0, "locked": true},
		{"kind": "ball", "id": "m", "pos": Vector2(500, 400), "vel": Vector2(0, -500)},
		{"kind": "rope", "from": "m", "to": "p"},
	])
	board.start()
	await _steps(30)
	# Vol libre sur 0,25 s : 400 - 500 x 0,25 + 490 x 0,25² = 305.
	_near("corde détendue : la bille monte en vol libre", _pos("m").y, 305.0, 0.02)


## Corde de 200 px avec 100 px de mou : chute libre sur 100 px, puis la corde retient la bille.
func _test_slack() -> void:
	_level([
		{"kind": "plank", "id": "p", "pos": Vector2(500, 100), "len": 100.0, "locked": true},
		{"kind": "ball", "id": "m", "pos": Vector2(500, 300)},
		{"kind": "rope", "from": "m", "to": "p", "slack": 100.0},
	])
	board.start()
	_near("mou : longueur de la corde", _rope().rest_length, 300.0, 0.001)
	await _steps(15)
	_near("mou : chute libre au début", _pos("m").y, 300.0 + 0.5 * G * 0.125 * 0.125, 0.01)
	var lowest := 0.0
	for i in 240:
		await physics_frame
		lowest = maxf(lowest, _pos("m").y)
	_check("mou : la corde retient la bille à 400 px (%.1f)" % lowest, lowest < 403.0)
	_near("mou : la bille finit pendue au bout", _pos("m").y, 400.0, 0.01)


func _test_balloon_cut() -> void:
	_level([
		{"kind": "balloon", "id": "b", "pos": Vector2(500, 400)},
		{"kind": "ball", "id": "m", "pos": Vector2(500, 500)},
		{"kind": "rope", "from": "b", "to": "m"},
	])
	board.start()
	await _steps(10)
	(board.find_part("b") as BalloonPart).pop()
	await _steps(10)
	_check("ballon éclaté : la corde disparaît sans erreur", _rope().points().is_empty())


func _test_cascade() -> void:
	_level([{"kind": "ball", "id": "m", "pos": Vector2(300, 300)}], {"pulley": 1, "rope": 1})
	var layout := board.apply_layout([
		{"kind": "pulley", "id": "w", "pos": Vector2(300, 100)},
		{"kind": "rope", "from": "m", "via": ["w"], "to": "m"},
	])
	board.remove(layout[0])
	_check("poulie retirée : sa corde revient au bac", board.remaining("rope") == 1 and board.placed.is_empty())


func _test_sound_bank() -> void:
	var bank := Sfx.build_bank()
	for sound: String in bank:
		var wav: AudioStreamWAV = bank[sound]
		var peak := 0
		for i in range(0, wav.data.size(), 2):
			peak = maxi(peak, absi(wav.data.decode_s16(i)))
		var seconds := wav.data.size() / 2.0 / wav.mix_rate
		_check("son %s : %.2fs, crête %d" % [sound, seconds, peak],
				peak > 20000 and peak < 32767 and seconds < 1.2)
		var dir := OS.get_environment("WAV_DIR")
		if dir != "":
			wav.save_to_wav("%s/%s.wav" % [dir, sound])


## Chaque mécanisme déclenche bien son son, en vraie simulation.
func _test_sound_events() -> void:
	board.sfx.counts.clear()
	_level([
		{"kind": "ball_heavy", "pos": Vector2(200, 400)},
		{"kind": "crate", "pos": Vector2(320, 400)},
		{"kind": "ball", "pos": Vector2(440, 400)},
		{"kind": "balloon", "pos": Vector2(560, 120)},
		{"kind": "spikes", "pos": Vector2(560, 30), "rot": 180.0},
		{"kind": "ball", "pos": Vector2(660, 300)},
		{"kind": "spring", "pos": Vector2(660, 620)},
		{"kind": "ball", "pos": Vector2(800, 400)},
		{"kind": "plate", "pos": Vector2(800, 620), "channel": 1},
		{"kind": "lamp", "pos": Vector2(980, 600), "channel": 1},
		{"kind": "cannon", "pos": Vector2(100, 60), "channel": 1},
	])
	board.start()
	await _steps(240)
	for sound: String in ["thud", "wood", "knock", "pop", "spring", "plate", "lamp", "cannon"]:
		_check("déclenché : %s (%d)" % [sound, board.sfx.counts.get(sound, 0)], board.sfx.counts.has(sound))
