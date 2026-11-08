class_name LevelData
## Niveaux et mondes. Les niveaux du jeu sont des fichiers de données dans res://levels ; voici
## leurs champs :
## `id`, `world`, `name` ; `goal_text`, `intro`, `hint` : textes affichés ;
## `fixed` : décor ; `inventory` : pièces du joueur ; `gravity`, `wind` : physique du niveau ;
## `solution` : disposition rejouée par tests/test_levels.gd pour prouver que le niveau se résout ;
## `par_time` : temps de l'objectif bonus « Rapide », que la solution doit tenir ;
## `challenge` : niveau « défi », fermé tant que son monde n'a pas toutes ses étoiles ;
## `tutorial` : étapes guidées du niveau.

static var dir := LevelFile.DIR
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
	{"id": "jardin", "name": "Jardin", "color": Color("1e3324")},
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


## Niveau jouable tiré du plan de travail de l'éditeur. Les pièces du décor gardent leur
## identifiant s'il est parlant (« bille », « boulet » : un tutoriel ou une solution s'y réfèrent) ;
## les autres deviennent « d1, d2… » (les cordes suivent) pour ne jamais croiser ceux du joueur.
static func from_editor(id: String, name: String, goal_text: String, decor: Array, inventory: Dictionary,
		gravity: float, wind: Vector2) -> Dictionary:
	var fixed := remap_ids(decor, decor_ids(decor))
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
		_levels = LevelFile.load_dir(dir)
	return _levels.duplicate(true)


## Change le dossier des niveaux du jeu (les tests travaillent sur une copie) et relit les niveaux.
static func set_dir(p_dir: String) -> void:
	dir = p_dir
	_levels.clear()


## Identifiant posé automatiquement (« p3 » par le plateau, « d2 » par l'éditeur, « f1 » au
## chargement), qu'on peut renuméroter sans rien casser.
static func is_auto_id(id: String) -> bool:
	return id == "" or (id.length() > 1 and id[0] in ["p", "d", "f"] and id.substr(1).is_valid_int())


## Nouveaux identifiants du décor : ancien → nouveau. Les noms parlants sont gardés.
static func decor_ids(decor: Array) -> Dictionary:
	var named := {}
	for entry: Dictionary in decor:
		if not is_auto_id(entry.get("id", "")):
			named[entry.id] = true
	var ids := {}
	var next := 1
	for entry: Dictionary in decor:
		var old: String = entry.get("id", "")
		if not is_auto_id(old):
			ids[old] = old
			continue
		while named.has("d%d" % next):
			next += 1
		ids[old] = "d%d" % next
		next += 1
	return ids


## Copie de pièces dont les identifiants, et les attaches des cordes, suivent `ids`.
static func remap_ids(entries: Array, ids: Dictionary) -> Array:
	var out: Array = []
	for entry: Dictionary in entries:
		var copy: Dictionary = entry.duplicate(true)
		if copy.has("id") and ids.has(copy.id):
			copy.id = ids[copy.id]
		for key: String in ["from", "to"]:
			if copy.has(key):
				copy[key] = ids.get(copy[key], copy[key])
		if copy.has("via"):
			var via: Array = []
			for v: String in copy.via:
				via.append(ids.get(v, v))
			copy.via = via
		out.append(copy)
	return out


## Niveau du jeu tiré d'un niveau de l'éditeur : fiche (`meta` : id, world, challenge, intro, hint,
## par_time, tutorial), solution vérifiée, et décor débarrassé des identifiants auxquels rien ne se réfère.
static func to_official(level: Dictionary, meta: Dictionary, solution: Array) -> Dictionary:
	var used := {}
	for entry: Dictionary in level.fixed + solution:
		for key: String in ["from", "to"]:
			if entry.has(key):
				used[entry[key]] = true
		for v: String in entry.get("via", []):
			used[v] = true
	for step: Dictionary in meta.get("tutorial", []):
		var target: String = step.get("target", "")
		if target.begins_with("part:"):
			used[target.substr(5)] = true
	var fixed: Array = []
	for entry: Dictionary in level.fixed:
		var copy: Dictionary = entry.duplicate(true)
		if is_auto_id(copy.get("id", "")) and not used.has(copy.get("id", "")):
			copy.erase("id")
		fixed.append(copy)
	var official := {
		"id": meta.id, "world": meta.world, "name": level.name, "goal_text": level.goal_text,
		"intro": meta.get("intro", level.goal_text), "hint": meta.get("hint", ""),
		"fixed": fixed, "inventory": level.inventory, "solution": solution.duplicate(true),
	}
	if meta.get("par_time", 0.0) > 0.0:
		official.par_time = meta.par_time
	if meta.get("challenge", false):
		official.challenge = true
	if level.get("gravity", 1.0) != 1.0:
		official.gravity = level.gravity
	if level.get("wind", Vector2.ZERO) != Vector2.ZERO:
		official.wind = level.wind
	if not meta.get("tutorial", []).is_empty():
		official.tutorial = meta.tutorial
	return official
