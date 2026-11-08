class_name Gallery
## Galerie de niveaux partagés. Son contenu est un fichier `gallery/index.cfg` du dépôt du jeu,
## une section par niveau :
##
##     [fronde]
##     name="La fronde"
##     author="Bric-à-Brac"
##     added="2026-11-08"
##     difficulty=1
##     code="BAB1:…"
##
## `code` est le code de partage du niveau (« Partager le niveau… » dans l'éditeur), qui contient
## la solution de l'auteur : le jeu la rejoue avant d'ajouter le niveau à « Mes niveaux ».
## `difficulty` (1 à 3) est l'estimation de l'auteur ; sans elle, on la déduit de la solution.
## La galerie livrée avec le jeu peut être complétée par la version en ligne du même fichier,
## téléchargée à la demande. On propose un niveau en ouvrant une demande sur le dépôt.

const BUNDLED := "res://gallery/index.cfg"
const ONLINE_URL := "https://raw.githubusercontent.com/HackTechDev/bricabrac/master/gallery/index.cfg"
const ISSUE_URL := "https://github.com/HackTechDev/bricabrac/issues/new"
const LABELS: Array[String] = ["", "Facile", "Moyen", "Difficile"]


## Entrées lisibles d'un texte de galerie : {key, name, author, added, difficulty, code, level}.
## Les entrées dont le code est abîmé ou le niveau refusé sont écartées.
static func parse(text: String) -> Array:
	var cfg := ConfigFile.new()
	if cfg.parse(text) != OK:
		return []
	var entries: Array = []
	for key in cfg.get_sections():
		var payload: Variant = Share.decode(str(cfg.get_value(key, "code", "")))
		if not payload is Dictionary or payload.get("type", "") != "level":
			continue
		var level: Variant = Share.clean_level(payload.get("level"))
		if not level is Dictionary:
			continue
		var difficulty: Variant = cfg.get_value(key, "difficulty", 0)
		entries.append({
			"key": key,
			"name": str(cfg.get_value(key, "name", level.name)).left(60),
			"author": str(cfg.get_value(key, "author", "Anonyme")).left(40),
			"added": str(cfg.get_value(key, "added", "")).left(10),
			"difficulty": clampi(difficulty, 1, 3) if difficulty is int and difficulty > 0 else estimate(level),
			"code": cfg.get_value(key, "code"),
			"level": level,
		})
	return entries


static func load_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	return parse(FileAccess.get_file_as_string(path))


## Galerie livrée, complétée et mise à jour par la copie en ligne (même clé : la copie l'emporte).
static func merge(bundled: Array, online: Array) -> Array:
	var by_key := {}
	var order: Array = []
	for entry: Dictionary in bundled + online:
		if not by_key.has(entry.key):
			order.append(entry.key)
		by_key[entry.key] = entry
	var merged: Array = []
	for key: String in order:
		merged.append(by_key[key])
	return merged


## Difficulté déduite de la solution de l'auteur : nombre de pièces, cordes et engrenages qui
## demandent de la précision, physique inhabituelle.
static func estimate(level: Dictionary) -> int:
	var score := 0.0
	for entry: Dictionary in level.get("solution", []):
		score += 1.5 if entry.get("kind", "") in ["rope", "elastic", "gear", "spring", "portal"] else 1.0
	if level.get("gravity", 1.0) != 1.0 or level.get("wind", Vector2.ZERO) != Vector2.ZERO:
		score += 1.0
	return 1 if score <= 2.0 else 2 if score <= 3.5 else 3


## Tri : du plus facile au plus difficile, ou du plus récent au plus ancien.
static func sorted(entries: Array, newest_first: bool) -> Array:
	var out := entries.duplicate()
	if newest_first:
		out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return [b.added, a.name] < [a.added, b.name])
	else:
		out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return [a.difficulty, a.name] < [b.difficulty, b.name])
	return out


static func stars(difficulty: int) -> String:
	return "★".repeat(difficulty) + "☆".repeat(3 - difficulty) + "  " + Lang.t(LABELS[difficulty])


## Adresse qui ouvre une demande d'ajout à la galerie, code du niveau compris.
static func propose_url(level_name: String, code: String) -> String:
	var body := "Je propose ce niveau pour la galerie de Bric-à-Brac.\n\n" \
			+ "Nom : %s\nAuteur : \nDifficulté (1 à 3) : \n\nCode :\n\n%s\n" % [level_name, code]
	return "%s?title=%s&body=%s" % [ISSUE_URL, ("Galerie : " + level_name).uri_encode(), body.uri_encode()]
