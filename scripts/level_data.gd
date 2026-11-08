class_name LevelData
## Niveaux et mondes. Les niveaux du jeu sont des fichiers de données dans res://levels ; voici
## leurs champs :
## `id`, `world`, `name` ; `goal_text`, `intro`, `hint` : textes affichés ;
## `fixed` : décor ; `inventory` : pièces du joueur ; `gravity`, `wind` : physique du niveau ;
## `solution` : disposition rejouée par tests/test_levels.gd pour prouver que le niveau se résout ;
## `par_time` : temps de l'objectif bonus « Rapide », que la solution doit tenir ;
## `tutorial` : étapes guidées du niveau.

static var _levels: Array = []


## Nombre de pièces du bac à sable : le bac affiche « ∞ ».
const UNLIMITED := 99


## Bac à sable : toutes les pièces, aucun objectif ; la gravité et le vent se règlent en haut.
static func sandbox() -> Dictionary:
	var inventory := {}
	for kind: String in Catalog.INFO:
		inventory[kind] = UNLIMITED
	return {
		"id": "bac_a_sable",
		"name": "Bac à sable",
		"sandbox": true,
		"goal_text": "Construis librement, sans objectif.",
		"intro": "Toutes les pièces sont là, en quantité illimitée. Règle la gravité et le vent en haut.",
		"hint": "Pas d'objectif ici : essaie une pièce, lance, observe. Tes machines sont gardées.",
		"fixed": [],
		"inventory": inventory,
	}


## Mondes à thème, dans l'ordre du jeu ; chaque niveau porte l'identifiant du sien.
const WORLDS: Array[Dictionary] = [
	{"id": "atelier", "name": "Atelier", "color": Color("1d2b45")},
	{"id": "cuisine", "name": "Cuisine", "color": Color("3a2a24")},
	{"id": "usine", "name": "Usine", "color": Color("262d2a")},
	{"id": "espace", "name": "Espace", "color": Color("120f2a")},
	{"id": "perso", "name": "Mes niveaux", "color": Color("23303a")},
]
## Pièces qui peuvent servir d'objectif à un niveau.
const GOAL_KINDS: Array[String] = ["basket", "lamp", "balloon"]


static func world(id: String) -> Dictionary:
	for w in WORLDS:
		if w.id == id:
			return w
	return WORLDS[0]


## Plan de travail de l'éditeur : toutes les pièces, sans limite ; ce qu'on y pose devient le décor.
static func editor_level() -> Dictionary:
	var level := sandbox()
	level.merge({
		"id": "editeur",
		"name": "Éditeur de niveaux",
		"editor": true,
		"goal_text": "Pose le décor et marque l'objectif avec G.",
		"intro": "Tout ce que tu poses ici fait partie du décor. G marque l'objectif : panier, lampe ou ballon.",
		"hint": "Un bon niveau : un objectif, un décor qui l'empêche de se gagner seul, et juste assez de pièces.",
	}, true)
	return level


## Niveau jouable tiré du plan de travail de l'éditeur. Les pièces du décor reçoivent des
## identifiants « d1, d2… » (les cordes suivent) pour ne jamais croiser ceux du joueur.
static func from_editor(id: String, name: String, goal_text: String, decor: Array, inventory: Dictionary,
		gravity: float, wind: Vector2) -> Dictionary:
	var ids := {}
	var fixed: Array = []
	for entry: Dictionary in decor:
		ids[entry.get("id", "")] = "d%d" % (ids.size() + 1)
	for entry: Dictionary in decor:
		var copy: Dictionary = entry.duplicate(true)
		copy.id = ids[entry.get("id", "")]
		for key: String in ["from", "to"]:
			if copy.has(key):
				copy[key] = ids.get(copy[key], copy[key])
		if copy.has("via"):
			var via: Array = []
			for v: String in copy.via:
				via.append(ids.get(v, v))
			copy.via = via
		fixed.append(copy)
	var counts := {}
	for kind: String in inventory:
		if inventory[kind] > 0:
			counts[kind] = inventory[kind]
	return {
		"id": id, "name": name, "goal_text": goal_text, "world": "perso", "custom": true,
		"intro": goal_text, "hint": "Niveau créé dans l'éditeur.",
		"fixed": fixed, "inventory": counts, "gravity": gravity, "wind": wind,
	}


## Empreinte de ce qui fait un niveau (décor, inventaire, physique), sans son nom : une solution
## trouvée pour une empreinte ne vaut plus si elle change.
static func signature(level: Dictionary) -> int:
	return var_to_str([level.get("fixed", []), level.get("inventory", {}), level.get("gravity", 1.0),
			level.get("wind", Vector2.ZERO)]).hash()


static func has_goal(level: Dictionary) -> bool:
	for entry: Dictionary in level.get("fixed", []):
		if entry.get("goal", false):
			return true
	return false


## Niveaux du jeu, lus une fois dans res://levels (voir LevelFile). Chaque appel rend une copie.
static func all() -> Array:
	if _levels.is_empty():
		_levels = LevelFile.load_dir()
	return _levels.duplicate(true)
