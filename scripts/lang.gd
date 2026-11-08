class_name Lang
## Langue de l'interface. Les textes du jeu sont écrits en français dans le code et les niveaux ;
## `i18n/<code>.json` associe à chacun sa traduction (texte français → texte traduit). Un texte
## sans traduction s'affiche en français.

const DIR := "res://i18n"
## Langues proposées : code, nom affiché dans la langue elle-même.
const LANGUAGES: Array = [["fr", "Français"], ["en", "English"]]

static var current := "fr"
static var _loaded := {}


static func use(code: String) -> void:
	if not _has(code):
		code = "fr"
	if code != "fr" and not _loaded.has(code):
		var translation := Translation.new()
		translation.locale = code
		var messages: Dictionary = messages(code)
		for source: String in messages:
			translation.add_message(source, messages[source])
		_loaded[code] = translation
	# Seule la langue choisie reste chargée : sinon Godot se rabattrait sur l'anglais (sa langue
	# de repli) pour tout texte sans traduction française, c'est-à-dire tous.
	for loaded: String in _loaded:
		TranslationServer.remove_translation(_loaded[loaded])
	if _loaded.has(code):
		TranslationServer.add_translation(_loaded[code])
	current = code
	TranslationServer.set_locale(code)


## Texte traduit dans la langue choisie.
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))


static func messages(code: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [DIR, code]))
	return data if data is Dictionary else {}


static func index_of(code: String) -> int:
	for i in LANGUAGES.size():
		if LANGUAGES[i][0] == code:
			return i
	return 0


static func _has(code: String) -> bool:
	return LANGUAGES.any(func(l: Array) -> bool: return l[0] == code)


## Séparateur décimal de la langue : « 1,5 s » en français, « 1.5 s » en anglais.
static func decimal_mark() -> String:
	return "," if current == "fr" else "."
