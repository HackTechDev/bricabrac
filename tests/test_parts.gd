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
	await _test_portals()
	await _test_water()
	await _test_level_physics()
	await _test_wind_shelter()
	await _test_suction()
	await _test_cart()
	await _test_mouse_wheel()
	await _test_cat()
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


## La bille tombe dans un portail couché et ressort de l'autre, à la même vitesse : couché, elle
## continue de tomber ; debout, sa chute devient horizontale. Sans partenaire, rien ne se passe.
func _test_portals() -> void:
	for exit_rot: float in [90.0, 0.0]:
		_level([
			{"kind": "ball", "id": "b", "pos": Vector2(200, 250)},
			{"kind": "portal", "pos": Vector2(200, 500), "rot": 90.0, "channel": 1},
			{"kind": "portal", "pos": Vector2(700, 200), "rot": exit_rot, "channel": 1},
		])
		board.start()
		var before := Vector2.ZERO
		for i in 360:
			if _pos("b").x > 400.0:
				break
			before = _rigid("b").linear_velocity
			await _steps(1)
		var after := _rigid("b").linear_velocity
		var label := "portail %d°" % exit_rot
		_near(label + " : la bille ressort de l'autre", _pos("b").x, 700.0, 0.01)
		_near(label + " : même vitesse", after.length(), before.length(), 0.03)
		var expected := Vector2.DOWN if exit_rot == 90.0 else Vector2.RIGHT
		_check(label + " : direction tournée", after.normalized().dot(expected) > 0.95)
		await _steps(60)
		_check(label + " : pas de va-et-vient", _pos("b").x > 600.0)
	_level([
		{"kind": "ball", "id": "b", "pos": Vector2(200, 250)},
		{"kind": "portal", "pos": Vector2(200, 500), "rot": 90.0, "channel": 1},
		{"kind": "portal", "pos": Vector2(700, 200), "rot": 90.0, "channel": 2},
	])
	board.start()
	await _steps(120)
	_near("portail seul : la bille le traverse", _pos("b").x, 200.0, 0.01)


## Lâchés au-dessus du bac, les objets légers flottent et les lourds coulent jusqu'au fond.
func _test_water() -> void:
	var tank := Vector2(500, 500)
	var surface := tank.y + WaterPart.INNER.y / 2.0 - WaterPart.DEPTH
	var bottom := tank.y + WaterPart.INNER.y / 2.0
	_level([
		{"kind": "water", "pos": tank},
		{"kind": "crate", "id": "caisse", "pos": Vector2(430, 300)},
		{"kind": "ball_bouncy", "id": "balle", "pos": Vector2(500, 300)},
		{"kind": "ball", "id": "bille", "pos": Vector2(560, 300)},
		{"kind": "ball_heavy", "id": "boulet", "pos": Vector2(470, 200)},
	])
	board.start()
	await _steps(600)
	for id: String in ["caisse", "balle"]:
		var y := _pos(id).y
		_check("eau : %s flotte (%.0f, surface %.0f)" % [id, y, surface], absf(y - surface) < 20.0)
		_check("eau : %s au repos" % id, _rigid(id).linear_velocity.length() < 20.0)
	for id: String in ["bille", "boulet"]:
		_check("eau : %s au fond (%.0f)" % [id, _pos(id).y], _pos(id).y > bottom - 30.0)
	_check("eau : le bac retient tout", absf(_pos("caisse").x - tank.x) < WaterPart.INNER.x / 2.0)


## Gravité réduite : chute quatre fois plus courte. Vent : il pousse le léger bien plus que le lourd,
## et tout redevient normal au niveau suivant.
func _test_level_physics() -> void:
	var drop := {}
	for g: float in [1.0, 0.25]:
		_level([{"kind": "ball", "id": "b", "pos": Vector2(200, 100)}], {}, {"gravity": g})
		board.start()
		await _steps(60)
		drop[g] = _pos("b").y - 100.0
	_near("gravité ×0,25 : chute réduite d'autant", drop[0.25] / drop[1.0], 0.25, 0.03)
	_level([
		{"kind": "ball_bouncy", "id": "balle", "pos": Vector2(200, 100)},
		{"kind": "ball_heavy", "id": "boulet", "pos": Vector2(500, 100)},
	], {}, {"wind": Vector2(300, 0)})
	board.start()
	await _steps(60)
	var light := _pos("balle").x - 200.0
	var heavy := _pos("boulet").x - 500.0
	_near("vent : la balle rebond dérive", light, 0.5 * 0.25 * 300.0 * 0.001 * PI * 15.0 * 15.0 / 0.8, 0.1)
	_check("vent : le boulet dérive trois fois moins (%.0f contre %.0f px)" % [heavy, light],
			heavy > 0.0 and heavy * 3.0 < light)
	_level([{"kind": "ball", "id": "b", "pos": Vector2(200, 100)}])
	board.start()
	await _steps(60)
	_near("niveau suivant : gravité normale", _pos("b").y - 100.0, drop[1.0], 0.01)
	_near("niveau suivant : pas de vent", _pos("b").x, 200.0, 0.001)


## Le vent s'arrête aux obstacles : une balle posée derrière un mur ne bouge pas, une balle à
## moitié cachée dérive moins qu'une balle à découvert. Pareil pour le souffle d'un ventilateur.
func _test_wind_shelter() -> void:
	var drift := {}
	for wall: String in ["aucun", "entier", "bas"]:
		var fixed: Array = [{"kind": "ball_bouncy", "id": "b", "pos": Vector2(600, 625)}]
		if wall == "entier":
			fixed.append({"kind": "plank", "pos": Vector2(500, 560), "len": 160.0, "rot": 90.0, "locked": true})
		elif wall == "bas":
			fixed.append({"kind": "plank", "pos": Vector2(500, 680), "len": 120.0, "rot": 90.0, "locked": true})
		_level(fixed, {}, {"wind": Vector2(300, 0)})
		board.start()
		await _steps(60)
		drift[wall] = _pos("b").x - 600.0
	_check("vent : la balle à découvert dérive (%.1f px)" % drift["aucun"], drift["aucun"] > 5.0)
	_check("vent : abritée derrière un mur, elle ne bouge pas (%.2f px)" % drift["entier"],
			absf(drift["entier"]) < 0.05 * drift["aucun"])
	_check("vent : à moitié abritée, elle dérive moins (%.1f px)" % drift["bas"],
			drift["bas"] > 0.15 * drift["aucun"] and drift["bas"] < 0.8 * drift["aucun"])
	var pushed := {}
	for wall: bool in [false, true]:
		var fixed: Array = [
			{"kind": "fan", "pos": Vector2(200, 600)},
			{"kind": "ball_bouncy", "id": "b", "pos": Vector2(420, 625)},
		]
		if wall:
			fixed.append({"kind": "plank", "pos": Vector2(320, 580), "len": 120.0, "rot": 90.0, "locked": true})
		_level(fixed)
		board.start()
		await _steps(60)
		pushed[wall] = _pos("b").x - 420.0
	_check("ventilateur : pousse la balle (%.1f px)" % pushed[false], pushed[false] > 5.0)
	_check("ventilateur : le mur arrête son souffle (%.2f px)" % pushed[true], absf(pushed[true]) < 0.5)


## Lancée vers le haut, la bille frappe une ventouse retournée : elle est retenue, puis lâchée quand
## la minuterie allume le canal. Une ventouse sur le canal 0 garde sa prise.
func _test_suction() -> void:
	_level([
		{"kind": "ball", "id": "b", "pos": Vector2(300, 500), "vel": Vector2(0, -700)},
		{"kind": "suction", "id": "v", "pos": Vector2(300, 300), "rot": 180.0, "channel": 1},
		{"kind": "ball", "id": "b2", "pos": Vector2(600, 500), "vel": Vector2(0, -700)},
		{"kind": "suction", "pos": Vector2(600, 300), "rot": 180.0},
		{"kind": "timer", "pos": Vector2(900, 600), "channel": 1, "delay": 2.0},
	])
	board.start()
	await _steps(180)
	_check("ventouse : la bille est retenue", _pos("b").y > 310.0 and _pos("b").y < 360.0 and _rigid("b").linear_velocity.length() < 20.0)
	_check("ventouse : prise signalée", (board.find_part("v") as SuctionPart).held != null)
	await _steps(120)
	_check("ventouse : lâchée par son canal", _pos("b").y > 450.0)
	_check("ventouse canal 0 : garde sa prise", _pos("b2").y < 360.0)


## Rail incliné : le chariot descend jusqu'au butoir sans quitter le rail. Rail plat : un boulet
## tombé dessus reste à bord pendant que le ventilateur pousse le chariot.
func _test_cart() -> void:
	_level([{"kind": "cart", "id": "c", "pos": Vector2(500, 300), "rot": 15.0}])
	board.start()
	await _steps(360)
	var along := (_pos("c") - Vector2(500, 300)).rotated(-deg_to_rad(15.0))
	_near("chariot : au bout du rail", along.x, (CartPart.RAIL.x - CartPart.CART.x) / 2.0, 0.05)
	_near("chariot : reste sur le rail", along.y, -CartPart.RIDE, 0.05)
	_level([
		{"kind": "cart", "id": "c", "pos": Vector2(500, 400)},
		{"kind": "ball_heavy", "id": "k", "pos": Vector2(500, 300)},
		{"kind": "fan", "pos": Vector2(250, 385)},
	])
	board.start()
	await _steps(240)
	_check("chariot : poussé par le vent (%.0f)" % _pos("c").x, _pos("c").x > 560.0)
	_check("chariot : le boulet reste à bord", absf(_pos("k").x - _pos("c").x) < 30.0 and _pos("k").y < 400.0)


## La souris dort ; une bille tombe sur sa roue, elle se réveille et entraîne l'engrenage voisin.
## Une autre souris, que rien ne dérange, dort toujours.
func _test_mouse_wheel() -> void:
	_level([
		{"kind": "mousewheel", "id": "s", "pos": Vector2(300, 400)},
		{"kind": "gear", "id": "g", "pos": Vector2(384, 400)},
		{"kind": "ball", "pos": Vector2(270, 200)},
		{"kind": "mousewheel", "id": "s2", "pos": Vector2(800, 400)},
	])
	_check("souris : engrène avec la roue", board.gear_neighbors(board.find_part("s")).size() == 1)
	board.start()
	await _steps(20)
	_check("souris : dort au départ", not (board.find_part("s") as MouseWheelPart).awake)
	await _steps(120)
	_check("souris : réveillée par la bille", (board.find_part("s") as MouseWheelPart).awake)
	_near("souris : entraîne l'engrenage", _spin("g"), -MouseWheelPart.RUN_SPEED * 44.0 / 40.0, 0.03)
	_check("souris : l'autre dort encore", not (board.find_part("s2") as MouseWheelPart).awake)


## Le chat bondit sur la bille qui roule devant lui et la rattrape ; tourné de l'autre côté, il ne
## voit rien et reste assis.
func _test_cat() -> void:
	for facing: int in [1, -1]:
		_level([
			{"kind": "cat", "id": "chat", "pos": Vector2(300, 625), "dir": facing},
			{"kind": "ball", "id": "b", "pos": Vector2(700, 624), "vel": Vector2(-150, 0)},
		])
		board.start()
		var closest := INF
		for i in 240:
			await _steps(1)
			closest = minf(closest, _pos("chat").distance_to(_pos("b")))
		var cat := board.find_part("chat") as CatPart
		if facing == 1:
			_check("chat : bondit sur ce qui bouge", cat.leaps >= 1)
			_check("chat : atteint la bille (%.0f px)" % closest, closest < 45.0)
		else:
			_check("chat : ne voit pas derrière lui", cat.leaps == 0)


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
