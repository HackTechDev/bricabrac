class_name Share
## Partage des niveaux et des solutions sous forme de code texte, à copier-coller ou à enregistrer
## dans un fichier .bab. Le code est la sérialisation binaire de Godot (sans objets), compressée,
## en base 64, précédée d'un préfixe de version.
##
## Tout ce qui est importé passe par `clean_level` ou `clean_layout` : seuls les champs connus, du
## bon type et dans des bornes raisonnables sont gardés. Rien n'est exécuté.

const PREFIX := "BAB1:"
const MAX_BYTES := 262144
const MAX_ENTRIES := 300
const EXTENSION := "bab"

## Champs admis dans une pièce, avec leur type.
const FIELDS := {
	"kind": TYPE_STRING, "id": TYPE_STRING, "pos": TYPE_VECTOR2, "rot": TYPE_FLOAT, "dir": TYPE_INT,
	"channel": TYPE_INT, "len": TYPE_FLOAT, "slack": TYPE_FLOAT, "tension": TYPE_FLOAT,
	"delay": TYPE_FLOAT, "goal": TYPE_BOOL, "locked": TYPE_BOOL, "from": TYPE_STRING,
	"to": TYPE_STRING, "via": TYPE_ARRAY, "from_off": TYPE_VECTOR2, "to_off": TYPE_VECTOR2,
	"vel": TYPE_VECTOR2,
}


static func encode(payload: Dictionary) -> String:
	var raw := var_to_bytes(payload)
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	return PREFIX + Marshalls.raw_to_base64(packed)


## Contenu d'un code, ou message d'erreur (String) s'il est illisible.
static func decode(code: String) -> Variant:
	var text := code.strip_edges().replace("\n", "").replace(" ", "")
	if not text.begins_with(PREFIX):
		return "Ce n'est pas un code Bric-à-Brac."
	var body := text.substr(PREFIX.length())
	var regex := RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")
	if body.length() % 4 != 0 or regex.search(body) == null:
		return "Code incomplet ou abîmé."
	var packed := Marshalls.base64_to_raw(body)
	if packed.is_empty():
		return "Code incomplet ou abîmé."
	var raw := packed.decompress_dynamic(MAX_BYTES, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		return "Code incomplet ou abîmé."
	var value: Variant = bytes_to_var(raw)
	if not value is Dictionary:
		return "Code incomplet ou abîmé."
	return value


static func level_payload(level: Dictionary) -> Dictionary:
	var copy := {}
	for key: String in ["id", "name", "goal_text", "fixed", "inventory", "gravity", "wind", "solution"]:
		if level.has(key):
			copy[key] = level[key]
	return {"type": "level", "level": copy}


static func solution_payload(level: Dictionary, layout: Array) -> Dictionary:
	return {"type": "solution", "level_id": level.id, "signature": LevelData.signature(level),
			"layout": layout}


## Pièce nettoyée, ou null si elle n'est pas acceptable.
static func clean_entry(item: Variant) -> Variant:
	if not item is Dictionary or not Catalog.INFO.has(item.get("kind", "")):
		return null
	var entry := {}
	for key: String in item:
		if not FIELDS.has(key):
			continue
		var value: Variant = item[key]
		var wanted: int = FIELDS[key]
		if wanted == TYPE_FLOAT and typeof(value) == TYPE_INT:
			value = float(value)
		if typeof(value) != wanted:
			return null
		if value is float and not is_finite(value):
			return null
		if value is Vector2 and not (value as Vector2).is_finite():
			return null
		if key == "via":
			for v: Variant in value:
				if not v is String:
					return null
		entry[key] = value
	if not Catalog.is_link(entry.kind):
		if not entry.has("pos"):
			return null
		var pos: Vector2 = entry.pos
		if pos.x < -50.0 or pos.y < -50.0 or pos.x > Board.SIZE.x + 50.0 or pos.y > Board.SIZE.y + 50.0:
			return null
	return entry


static func clean_layout(items: Variant) -> Variant:
	if not items is Array or (items as Array).size() > MAX_ENTRIES:
		return null
	var result: Array = []
	for item: Variant in items:
		var entry: Variant = clean_entry(item)
		if entry == null:
			return null
		result.append(entry)
	return result


## Niveau nettoyé, ou message d'erreur.
static func clean_level(raw: Variant) -> Variant:
	if not raw is Dictionary:
		return "Niveau illisible."
	var fixed: Variant = clean_layout(raw.get("fixed", []))
	var solution: Variant = clean_layout(raw.get("solution", []))
	if fixed == null or solution == null:
		return "Le niveau contient des pièces inconnues ou mal décrites."
	var inventory := {}
	var given: Variant = raw.get("inventory", {})
	if not given is Dictionary:
		return "Inventaire illisible."
	for kind: Variant in given:
		var count: Variant = given[kind]
		if not kind is String or not Catalog.INFO.has(kind) or not count is int or count < 0 or count > 99:
			return "Inventaire illisible."
		if count > 0:
			inventory[kind] = count
	var gravity: Variant = raw.get("gravity", 1.0)
	var wind: Variant = raw.get("wind", Vector2.ZERO)
	if not (gravity is float and gravity >= 0.0 and gravity <= 3.0 and wind is Vector2 and wind.length() <= 600.0):
		return "Gravité ou vent hors des limites."
	var text := func(key: String, fallback: String) -> String:
		var value: Variant = raw.get(key, fallback)
		return (value as String).left(80) if value is String and value.strip_edges() != "" else fallback
	var level := {
		"id": text.call("id", "importe"), "name": text.call("name", "Niveau importé"),
		"goal_text": text.call("goal_text", "Atteins l'objectif."), "fixed": fixed,
		"inventory": inventory, "gravity": gravity, "wind": wind, "solution": solution,
	}
	if not LevelData.has_goal(level):
		return "Ce niveau n'a pas d'objectif."
	if (solution as Array).is_empty():
		return "Ce niveau n'a pas été résolu par son auteur : il ne peut pas être importé."
	return level
