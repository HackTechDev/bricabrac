extends "res://tests/ui_driver.gd"
## Traduction : chaque texte d'interface et de niveau a sa version anglaise, avec les mêmes
## emplacements (%d, %s…), et l'interface s'affiche en anglais quand on la choisit.
## godot --headless --path . --fixed-fps 120 -s tests/test_lang.gd

const SCRIPT_DIRS: Array[String] = ["res://scripts", "res://scripts/parts"]


func _run() -> void:
	var en := Lang.messages("en")
	_check("dictionnaire anglais chargé (%d textes)" % en.size(), en.size() > 400)
	var missing := PackedStringArray()
	for text in _wrapped_texts():
		if _needs_translation(text) and not en.has(text):
			missing.append(text)
	for level: Dictionary in LevelFile.load_dir():
		for text in _level_texts(level):
			if not en.has(text):
				missing.append(text)
	for text in _level_texts(LevelData.sandbox()):
		if not en.has(text):
			missing.append(text)
	for kind: String in Catalog.INFO:
		for text: String in [Catalog.INFO[kind].label, Catalog.INFO[kind].desc]:
			if not en.has(text):
				missing.append(text)
	for world: Dictionary in LevelData.WORLDS:
		if not en.has(world.name):
			missing.append(world.name)
	_check("tout est traduit" + ("" if missing.is_empty() else " ; manquent :\n  " + "\n  ".join(missing)),
			missing.is_empty())
	var mismatched := PackedStringArray()
	for text: String in en:
		if _slots(text) != _slots(en[text]):
			mismatched.append(text)
	_check("mêmes emplacements %%d, %%s dans les traductions" + ("" if mismatched.is_empty() else " : " + ", ".join(mismatched)),
			mismatched.is_empty())

	Lang.use("en")
	_check("anglais : texte traduit", Lang.t("Lancer") == "Run" and Catalog.label("plank") == "Plank")
	_check("anglais : texte inconnu laissé tel quel", Lang.t("Bric-à-Brac") == "Bric-à-Brac")
	Lang.use("fr")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "language", "en")
	cfg.save(SAVE)
	await _launch(false, false)
	_check("langue enregistrée : l'interface démarre en anglais", main.language == "en")
	_check("anglais : bouton Lancer", main._run_button.text == "Run")
	_check("anglais : nom du niveau (%s)" % main._level_button.text, main._level_button.text.contains("First slope"))
	_check("anglais : objectif", main._goal_label.text.begins_with("Get the marble"))
	_check("anglais : bac", main._items[0].find_children("*", "Label", true, false).any(
			func(l: Label) -> bool: return l.text == "Plank"))
	main.set_language("fr")
	await _restart()
	_check("retour au français (%s, %s)" % [main.language, main._run_button.text], main.language == "fr" and main._run_button.text == "Lancer")
	_finish("TRADUCTION OK")


## Textes passés à Lang.t("…") dans les scripts.
func _wrapped_texts() -> PackedStringArray:
	var found := PackedStringArray()
	var pattern := RegEx.create_from_string("Lang\\.t\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	for dir in SCRIPT_DIRS:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			for m in pattern.search_all(FileAccess.get_file_as_string(dir + "/" + file)):
				found.append(m.get_string(1).c_unescape())
	return found


## Un texte qui n'a pas de mot (« %s s », « ×%s ») n'a pas besoin de traduction.
func _needs_translation(text: String) -> bool:
	var words := RegEx.create_from_string("%[-0-9.]*[a-z%]").sub(text, "", true)
	return RegEx.create_from_string("[A-Za-zÀ-ÿ]{3,}").search(words) != null


func _level_texts(level: Dictionary) -> PackedStringArray:
	var texts := PackedStringArray()
	for key: String in ["name", "goal_text", "intro", "hint"]:
		if level.get(key, "") != "":
			texts.append(level[key])
	for step: Dictionary in level.get("tutorial", []):
		for key: String in ["text", "running_text", "retry"]:
			if step.has(key):
				texts.append(step[key])
	return texts


func _slots(text: String) -> PackedStringArray:
	var slots := PackedStringArray()
	for m in RegEx.create_from_string("%[-0-9.]*[a-z%]").search_all(text):
		slots.append(m.get_string())
	return slots
