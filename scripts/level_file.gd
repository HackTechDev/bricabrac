class_name LevelFile
## Fichier de niveau : texte lisible au format ConfigFile, une section [niveau] dont chaque clé
## est un champ du niveau. Les listes de pièces s'écrivent une pièce par ligne :
##
##     [niveau]
##     id="pente"
##     world="atelier"
##     fixed=[
##     { "kind": "ball", "pos": Vector2(120, 80) },
##     { "kind": "basket", "pos": Vector2(900, 600), "goal": true }
##     ]
##
## Les niveaux du jeu sont dans res://levels, un fichier par niveau, joués dans l'ordre des noms
## (préfixe numérique). L'identifiant d'un niveau est celui écrit dans le fichier.

const SECTION := "niveau"
const DIR := "res://levels"
const EXTENSION := "cfg"
## Ordre d'écriture des champs connus, pour des fichiers faciles à relire ; les autres suivent.
const ORDER: Array[String] = ["id", "world", "name", "par_time", "goal_text", "intro", "hint",
		"gravity", "wind", "fixed", "inventory", "solution", "tutorial"]


## Texte du fichier pour un niveau.
static func to_text(level: Dictionary) -> String:
	var keys: Array = []
	for key: String in ORDER:
		if level.has(key):
			keys.append(key)
	for key: String in level:
		if not keys.has(key):
			keys.append(key)
	var lines := PackedStringArray(["[%s]" % SECTION, ""])
	for key: String in keys:
		lines.append("%s=%s" % [key, _format(level[key])])
	lines.append("")
	return "\n".join(lines)


## Niveau lu depuis un texte ; vide si le texte est illisible ou sans identifiant.
static func from_text(text: String) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.parse(text) != OK or not cfg.has_section(SECTION):
		return {}
	var level := {}
	for key in cfg.get_section_keys(SECTION):
		level[key] = cfg.get_value(SECTION, key)
	if not level.get("id", "") is String or level.get("id", "") == "":
		return {}
	return level


static func save(level: Dictionary, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_text(level))
	file.close()
	return OK


static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return from_text(FileAccess.get_file_as_string(path))


## Tous les niveaux d'un dossier, dans l'ordre des noms de fichier.
static func load_dir(dir := DIR) -> Array:
	var names := Array(DirAccess.get_files_at(dir)).filter(
			func(name: String) -> bool: return name.get_extension() == EXTENSION)
	names.sort()
	var levels: Array = []
	for name: String in names:
		var level := load_file(dir.path_join(name))
		if level.is_empty():
			push_error("Niveau illisible : %s" % dir.path_join(name))
		else:
			levels.append(level)
	return levels


## Fichiers de niveau d'un dossier, dans l'ordre : [{path, level}], les illisibles écartés.
static func list_dir(dir := DIR) -> Array:
	if not DirAccess.dir_exists_absolute(dir):
		return []
	var names := Array(DirAccess.get_files_at(dir)).filter(
			func(name: String) -> bool: return name.get_extension() == EXTENSION)
	names.sort()
	var files: Array = []
	for name: String in names:
		var level := load_file(dir.path_join(name))
		if not level.is_empty():
			files.append({"path": dir.path_join(name), "level": level})
	return files


## Chemin d'un nouveau niveau, numéroté après les autres : « 19_fronde.cfg ».
static func next_path(dir: String, id: String) -> String:
	var last := 0
	for name in DirAccess.get_files_at(dir):
		if name.get_extension() == EXTENSION:
			last = maxi(last, name.get_slice("_", 0).to_int())
	return dir.path_join(file_name(last + 1, {"id": id}))


## Nom de fichier conseillé : « 07_contrepoids.cfg ».
static func file_name(index: int, level: Dictionary) -> String:
	return "%02d_%s.%s" % [index, level.id, EXTENSION]


## Une valeur sur une ligne ; les listes de dictionnaires, un élément par ligne.
static func _format(value: Variant) -> String:
	if value is Array and not value.is_empty() and value.all(func(v: Variant) -> bool: return v is Dictionary):
		var items := PackedStringArray()
		for item: Dictionary in value:
			items.append(_inline(item))
		return "[\n%s\n]" % ",\n".join(items)
	return _inline(value)


static func _inline(value: Variant) -> String:
	if value is Dictionary:
		if value.is_empty():
			return "{}"
		var pairs := PackedStringArray()
		for key: Variant in value:
			pairs.append("%s: %s" % [var_to_str(key), _inline(value[key])])
		return "{ %s }" % ", ".join(pairs)
	if value is Array:
		var items := PackedStringArray()
		for item: Variant in value:
			items.append(_inline(item))
		return "[%s]" % ", ".join(items)
	return var_to_str(value)
