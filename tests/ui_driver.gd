extends SceneTree
## Aides partagées par les tests d'interface : lancer le jeu, puis le piloter avec de vrais
## événements souris et clavier, comme un joueur.

const SAVE := "user://test_ui_progress.cfg"
const CUSTOM_DIR := "user://test_ui_niveaux"

var main: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	pass


## Démarre le jeu ; `fresh` efface d'abord la sauvegarde de test.
func _launch(show_tutorials: bool, fresh := true) -> void:
	root.size = Vector2i(1280, 720)  # La fenêtre headless fait 64x64 par défaut.
	if fresh:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
		_clear_custom_dir()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.save_path = SAVE
	main.custom_dir = CUSTOM_DIR
	main.gallery_online_path = "user://test_ui_galerie.cfg"
	main.gallery_url = ""
	main.show_tutorials = show_tutorials
	main.show_title = false
	root.add_child(main)
	await process_frame
	await process_frame


func _clear_custom_dir() -> void:
	if not DirAccess.dir_exists_absolute(CUSTOM_DIR):
		return
	for name in DirAccess.get_files_at(CUSTOM_DIR):
		DirAccess.remove_absolute(CUSTOM_DIR.path_join(name))
	DirAccess.remove_absolute(CUSTOM_DIR)


func _finish(success: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	_clear_custom_dir()
	print("ÉCHECS : %d" % failures if failures else success)
	main.free()
	quit(1 if failures else 0)


func _restart() -> void:
	var tutorials: bool = main.show_tutorials
	main.free()
	await process_frame
	await _launch(tutorials, false)


func _bin_pos(kind: String) -> Vector2:
	for item: BinItem in main._items:
		if item.kind == kind:
			return item.get_global_rect().get_center()
	return Vector2.ZERO


func _drag(from: Vector2, to: Vector2) -> void:
	await _move(from)
	await _button(from, MOUSE_BUTTON_LEFT, true)
	await _move((from + to) / 2.0)
	await _move(to)
	await _button(to, MOUSE_BUTTON_LEFT, false)


func _click(at: Vector2, button: MouseButton, shift := false) -> void:
	await _move(at)
	await _button(at, button, true, shift)
	await _button(at, button, false, shift)


func _move(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	root.push_input(ev)
	await process_frame


func _button(at: Vector2, button: MouseButton, pressed: bool, shift := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.shift_pressed = shift
	ev.position = at
	ev.global_position = at
	ev.button_index = button
	ev.pressed = pressed
	root.push_input(ev)
	await process_frame


func _key(key: Key, ctrl := false, shift := false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.pressed = true
	root.push_input(ev)
	await process_frame


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "KO   ") + what)
	if not ok:
		failures += 1
