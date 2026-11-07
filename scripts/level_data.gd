class_name LevelData
## Niveaux du jeu. `fixed` : décor ; `inventory` : pièces du joueur ;
## `solution` : disposition rejouée par tests/test_levels.gd pour prouver que le niveau se résout.


static func steel(x: float, y: float, length: float, rot := 0.0) -> Dictionary:
	return {"kind": "plank", "pos": Vector2(x, y), "len": length, "rot": rot, "locked": true}


static func item(kind: String, x: float, y: float, extra := {}) -> Dictionary:
	var e := {"kind": kind, "pos": Vector2(x, y)}
	e.merge(extra)
	return e


static func all() -> Array:
	return [
		{
			"id": "pente",
			"name": "Première pente",
			"goal_text": "Amène la bille dans le panier doré.",
			"intro": "Glisse une pièce du bac vers le plateau, oriente-la avec R ou la molette, puis Lancer (Espace).",
			"hint": "La bille tombe tout droit : intercepte-la avec une planche inclinée vers la droite.",
			"fixed": [
				item("ball", 150, 60),
				item("basket", 480, 598, {"goal": true}),
			],
			"inventory": {"plank": 2},
			"solution": [
				{"kind": "plank", "pos": Vector2(190, 240), "rot": 30.0},
			],
		},
		{
			"id": "rebond",
			"name": "Par-dessus le mur",
			"goal_text": "Fais passer la bille au-dessus du mur, jusque dans le panier.",
			"intro": "Le ressort renvoie tout à la même vitesse, dans l'axe de sa face verte.",
			"hint": "Pose le ressort sous la bille et penche-le vers le mur.",
			"fixed": [
				item("ball", 200, 60),
				steel(520, 470, 340, 90.0),
				item("basket", 760, 598, {"goal": true}),
			],
			"inventory": {"spring": 1, "plank": 1},
			"solution": [
				{"kind": "spring", "pos": Vector2(200, 500), "rot": 15.0},
			],
		},
		{
			"id": "dominos",
			"name": "Effet domino",
			"goal_text": "Allume la lampe : un objet doit toucher la plaque.",
			"intro": "La bille finira dans la fosse… mais une rangée de dominos peut transmettre le choc au-delà.",
			"hint": "Un domino de chaque côté de la fosse, puis une file jusqu'au bout de l'étagère.",
			"fixed": [
				item("ball", 60, 150),
				steel(130, 215, 240, 12.0),
				steel(332, 260, 184),
				steel(417, 280, 54, 90.0),
				steel(444, 300, 68),
				steel(471, 280, 54, 90.0),
				steel(582, 260, 236),
				item("plate", 730, 626, {"channel": 1}),
				item("lamp", 950, 610, {"channel": 1, "goal": true}),
			],
			"inventory": {"domino": 5},
			"solution": [
				{"kind": "domino", "pos": Vector2(400, 220)},
				{"kind": "domino", "pos": Vector2(480, 220)},
				{"kind": "domino", "pos": Vector2(550, 220)},
				{"kind": "domino", "pos": Vector2(610, 220)},
				{"kind": "domino", "pos": Vector2(670, 220)},
			],
		},
		{
			"id": "courant",
			"name": "Courant d'air",
			"goal_text": "Fais éclater le ballon sur les pointes.",
			"intro": "Le ballon monte tout seul, mais le toit le bloque. Le vent pousse surtout ce qui est léger.",
			"hint": "Souffle le ballon hors de l'abri : il remontera de lui-même.",
			"fixed": [
				item("balloon", 300, 520, {"goal": true}),
				steel(280, 300, 480),
				item("spikes", 740, 30, {"rot": 180.0}),
			],
			"inventory": {"fan": 1, "plank": 1},
			"solution": [
				{"kind": "fan", "pos": Vector2(100, 400)},
			],
		},
		{
			"id": "bascule",
			"name": "Catapulte",
			"goal_text": "Envoie la bille bleue dans le panier en hauteur.",
			"intro": "La bascule penche à droite : une charge sur le côté gauche catapulte la bille bleue.",
			"hint": "Fais rouler le boulet jusqu'au côté gauche de la bascule.",
			"fixed": [
				item("ball_heavy", 90, 60),
				item("seesaw", 420, 596),
				item("ball", 510, 588),
				steel(800, 330, 220),
				item("basket", 800, 280, {"goal": true, "accepts": ["ball"]}),
			],
			"inventory": {"plank": 2},
			"solution": [
				{"kind": "plank", "pos": Vector2(110, 280), "rot": 30.0},
			],
		},
		{
			"id": "canon",
			"name": "Coup de canon",
			"goal_text": "Déclenche le canon et loge sa bille dans le panier.",
			"intro": "Une plaque alimente toutes les pièces du même canal. La touche C change le canal de ta pièce.",
			"hint": "La caisse doit tomber sur ta plaque ; règle le canon sur le même canal et vise haut.",
			"fixed": [
				item("crate", 120, 60),
				steel(800, 520, 260),
				item("basket", 800, 470, {"goal": true, "accepts": ["ball"]}),
			],
			"inventory": {"plate": 1, "cannon": 1},
			"solution": [
				{"kind": "plate", "pos": Vector2(120, 620), "channel": 1},
				{"kind": "cannon", "pos": Vector2(360, 520), "rot": 315.0, "channel": 1},
			],
		},
		{
			"id": "contrepoids",
			"name": "Contrepoids",
			"goal_text": "Fais monter la bille jusqu'à la plaque du haut pour allumer la lampe.",
			"intro": "Corde : clique le boulet, les poulies dans l'ordre, puis la bille. Le plus lourd entraîne l'autre.",
			"hint": "Une poulie au-dessus de la bille, une au-dessus du boulet, et la corde passe par les deux.",
			"fixed": [
				item("ball", 300, 610, {"id": "bille"}),
				item("ball_heavy", 700, 120, {"id": "boulet"}),
				item("plate", 300, 180, {"channel": 1, "rot": 180.0}),
				item("lamp", 950, 610, {"channel": 1, "goal": true}),
			],
			"inventory": {"pulley": 2, "rope": 1},
			"solution": [
				{"kind": "pulley", "id": "w1", "pos": Vector2(300, 40)},
				{"kind": "pulley", "id": "w2", "pos": Vector2(700, 40)},
				{"kind": "rope", "from": "boulet", "via": ["w2", "w1"], "to": "bille"},
			],
		},
		{
			"id": "pendule",
			"name": "Le pendule",
			"goal_text": "Fais tomber la caisse sur une plaque.",
			"intro": "Sans attache, le boulet tombe tout droit. Relié à la poutre, il se balance.",
			"hint": "Attache le boulet à la poutre, un peu à droite du milieu : son arc doit frapper la caisse de côté.",
			"fixed": [
				item("ball_heavy", 120, 300, {"id": "boulet"}),
				{"kind": "plank", "id": "poutre", "pos": Vector2(400, 60), "len": 300.0, "rot": 0.0, "locked": true},
				steel(560, 510, 50),
				item("crate", 560, 481),
				item("plate", 650, 626, {"channel": 1}),
				item("plate", 740, 626, {"channel": 1}),
				item("plate", 830, 626, {"channel": 1}),
				item("lamp", 950, 610, {"channel": 1, "goal": true}),
			],
			"inventory": {"rope": 1},
			"solution": [
				{"kind": "rope", "from": "boulet", "to": "poutre", "to_off": Vector2(60, 0)},
			],
		},
		{
			"id": "chaine",
			"name": "Réaction en chaîne",
			"goal_text": "Fais éclater le ballon : la bille doit démarrer toute la machine.",
			"intro": "Bille → plaque → tapis → caisse → seconde plaque → ventilateur → ballon.",
			"hint": "Deux canaux : le 1 démarre le tapis, le 2 le ventilateur. La seconde plaque va sous la sortie du tapis.",
			"fixed": [
				item("ball", 90, 60),
				item("conveyor", 480, 200, {"channel": 1}),
				item("crate", 450, 167),
				item("fan", 720, 560, {"channel": 2}),
				item("balloon", 870, 560, {"goal": true}),
				steel(860, 480, 180),
				item("spikes", 1000, 100, {"rot": 225.0}),
			],
			"inventory": {"plank": 1, "plate": 2},
			"solution": [
				{"kind": "plank", "pos": Vector2(140, 300), "rot": 30.0},
				{"kind": "plate", "pos": Vector2(320, 620), "channel": 1},
				{"kind": "plate", "pos": Vector2(560, 620), "channel": 2},
			],
		},
	]
