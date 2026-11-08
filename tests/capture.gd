extends SceneTree
## Capture chaque niveau (première bulle du tutoriel, atelier avec sa solution, simulation). Nécessite un affichage.
## CAPTURE_DIR=dossier godot --path . -s tests/capture.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dir := OS.get_environment("CAPTURE_DIR")
	var main: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.save_path = "user://capture_progress.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	root.add_child(main)
	await process_frame
	for i in main.levels.size():
		main.load_level(i)
		var board: Board = main.board
		await process_frame  # Le tutoriel démarre une image après le chargement.
		if main.tutorial.is_active():
			await _shot("%s/l%d_tuto.png" % [dir, i + 1])
		board.apply_layout(main.levels[i].solution)
		await _shot("%s/l%d_edit.png" % [dir, i + 1])
		main.toggle_run()
		var delay := create_timer(1.6)
		await delay.timeout
		await _shot("%s/l%d_run.png" % [dir, i + 1])
		main.toggle_run()
	main.free()
	quit()


func _shot(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
