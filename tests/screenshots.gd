extends SceneTree
## Captures d'écran du README, dans docs/captures/ (960×540). Nécessite un affichage :
## godot --path . -s tests/screenshots.gd

const OUT := "res://docs/captures"
const SIZE := Vector2i(960, 540)
## Niveaux filmés en marche : identifiant, nom du fichier, secondes de simulation avant la photo.
const RUNNING := [
	["chaine", "atelier", 2.2],
	["tri", "usine", 3.2],
	["chat_noir", "grenier", 1.0],
]

var main: Control


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	main.save_path = "user://captures_readme.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.show_tutorials = false
	root.add_child(main)
	# Le pointeur hors du plateau : pas de halo dans le grenier, pas d'infobulle.
	Input.warp_mouse(Vector2(1275, 715))
	await create_timer(1.0).timeout
	await _shot("titre")
	main.help_panel.open()
	await _shot("aide")
	main.help_panel.close()
	main.title_screen.hide()
	for shot: Array in RUNNING:
		main.load_level(_index(shot[0]))
		await create_timer(0.6).timeout  # Fin du balayage d'entrée.
		main.transition.hide()  # La carte du niveau ne masque pas la machine.
		main.board.apply_layout(main.levels[main.current].get("solution", []))
		main.toggle_run()
		await create_timer(shot[2]).timeout
		await _shot(shot[1])
		main.toggle_run()
		main.transition.show()
	main.open_level_select()
	await create_timer(1.5).timeout  # Les vignettes se rendent à la première ouverture.
	await _shot("selection")
	main.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://captures_readme.cfg"))
	quit()


func _index(id: String) -> int:
	for i in main.levels.size():
		if main.levels[i].id == id:
			return i
	return 0


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, name]))
	print("capture ", name)
