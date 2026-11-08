class_name ShareDialog
extends PopupPanel
## Fenêtre de partage : affiche un code à copier ou à enregistrer dans un fichier, ou reçoit un
## code collé ou lu dans un fichier pour l'importer.

signal import_requested(code: String)

var title_label: Label
var code_edit: TextEdit
var message: Label
var _copy: Button
var _save: Button
var _import: Button
var _open: Button
var _files: FileDialog
var _filename := "niveau"


func _init() -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(620, 0)
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	col.add_child(title_label)
	code_edit = TextEdit.new()
	code_edit.custom_minimum_size = Vector2(600, 180)
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	col.add_child(code_edit)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 600
	col.add_child(message)
	var row := HBoxContainer.new()
	col.add_child(row)
	_copy = _button(row, Lang.t("Copier le code"), func() -> void:
		DisplayServer.clipboard_set(code_edit.text)
		message.text = Lang.t("Code copié : colle-le où tu veux pour le partager."))
	_save = _button(row, Lang.t("Enregistrer dans un fichier…"), func() -> void: _browse(FileDialog.FILE_MODE_SAVE_FILE))
	_import = _button(row, Lang.t("Importer"), func() -> void: import_requested.emit(code_edit.text))
	_open = _button(row, Lang.t("Ouvrir un fichier…"), func() -> void: _browse(FileDialog.FILE_MODE_OPEN_FILE))
	_button(row, Lang.t("Fermer"), hide)
	_files = FileDialog.new()
	_files.access = FileDialog.ACCESS_FILESYSTEM
	_files.use_native_dialog = false
	_files.filters = PackedStringArray(["*.%s ; Bric-à-Brac" % Share.EXTENSION])
	_files.file_selected.connect(_on_file)
	add_child(_files)


func _button(row: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	row.add_child(b)
	return b


func show_export(heading: String, code: String, filename: String) -> void:
	title_label.text = heading
	code_edit.text = code
	code_edit.editable = false
	_filename = filename
	message.text = Lang.t("Copie ce code ou enregistre-le dans un fichier .%s.") % Share.EXTENSION
	_set_mode(true)
	popup_centered()


func show_import() -> void:
	title_label.text = Lang.t("Importer un niveau ou une solution")
	code_edit.text = ""
	code_edit.editable = true
	message.text = Lang.t("Colle un code Bric-à-Brac, ou ouvre un fichier .%s.") % Share.EXTENSION
	_set_mode(false)
	popup_centered()


func _set_mode(exporting: bool) -> void:
	_copy.visible = exporting
	_save.visible = exporting
	_import.visible = not exporting
	_open.visible = not exporting


func _browse(file_mode: FileDialog.FileMode) -> void:
	_files.file_mode = file_mode
	_files.title = Lang.t("Enregistrer le code") if file_mode == FileDialog.FILE_MODE_SAVE_FILE else Lang.t("Ouvrir un code")
	_files.current_file = "%s.%s" % [_filename.validate_filename(), Share.EXTENSION] \
			if file_mode == FileDialog.FILE_MODE_SAVE_FILE else ""
	_files.popup_centered(Vector2i(760, 480))


func _on_file(path: String) -> void:
	if _files.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		message.text = Lang.t("Enregistré dans %s.") % path if save_to(path) else Lang.t("Impossible d'écrire %s.") % path
	else:
		var text := FileAccess.get_file_as_string(path)
		code_edit.text = text
		import_requested.emit(text)


func save_to(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(code_edit.text + "\n")
	return true
