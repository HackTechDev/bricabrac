extends "res://tests/ui_driver.gd"
## Vérifie ce qui ne se voit qu'avec un rendu : vignettes des niveaux, cartes de l'écran de choix
## et carte de passage d'un niveau à l'autre. Le mode sans écran ne dessine rien : ce test
## demande un affichage et s'arrête sinon.
## godot --path . -s tests/test_render.gd


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("RENDU IGNORÉ : lancer sans --headless, avec un affichage")
		quit(0)
		return
	await _launch(false)
	await _test_thumbnails()
	await _test_cards()
	await _test_transition()
	_finish("RENDU OK")


## Chaque vignette montre le décor de son niveau : assez de pixels qui ne sont pas le fond, et
## aucune n'est identique à une autre.
func _test_thumbnails() -> void:
	main.open_level_select()
	for i in 4:
		await RenderingServer.frame_post_draw
	var select: Control = main._level_select
	var empty := PackedStringArray()
	var seen := {}
	var twins := PackedStringArray()
	for index: int in select._thumb_rects:
		var image: Image = select._thumb_rects[index].texture.get_image()
		var level: Dictionary = main.levels[index]
		if image == null or image.get_size() != Vector2i(Board.SIZE):
			empty.append("%s (pas d'image)" % level.id)
			continue
		var drawn := _drawn_fraction(image)
		if level.get("fixed", []).size() > 0 and drawn < 0.002:
			empty.append("%s (%.4f)" % [level.id, drawn])
		var key := str(hash(image.get_data()))
		if seen.has(key) and level.get("fixed", []).size() > 0:
			twins.append("%s = %s" % [level.id, seen[key]])
		seen[key] = level.id
	_check("vignettes : une par carte (%d)" % select._thumb_rects.size(),
			select._thumb_rects.size() == select._cards.size() and select._cards.size() >= 36)
	_check("vignettes : le décor apparaît" + ("" if empty.is_empty() else " ; vides : " + ", ".join(empty)),
			empty.is_empty())
	_check("vignettes : toutes différentes" + ("" if twins.is_empty() else " ; " + ", ".join(twins)),
			twins.is_empty())


## Sur l'écran, la première carte montre sa vignette et son nom sous l'image.
func _test_cards() -> void:
	var select: Control = main._level_select
	select.reveal(0)
	for i in 3:
		await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	var card: Control = select.card(0)
	var rect := Rect2i(card.get_global_rect())
	_check("carte 1 : à l'écran", Rect2i(Vector2i.ZERO, shot.get_size()).encloses(rect))
	var thumb_rect := Rect2i(select._thumb_rects[0].get_global_rect())
	_check("carte 1 : vignette rendue à l'écran", _drawn_fraction(shot.get_region(thumb_rect)) > 0.002)
	var text := Rect2i(rect.position.x, thumb_rect.end.y, rect.size.x, rect.end.y - thumb_rect.end.y)
	_check("carte 1 : nom écrit sous la vignette", _bright_fraction(shot.get_region(text)) > 0.01)
	select.hide()


## Pendant le passage au niveau suivant, la carte du nom apparaît au centre du plateau.
func _test_transition() -> void:
	main.load_level(1)
	var shown := false
	for i in 120:
		await RenderingServer.frame_post_draw
		if main.transition._card.modulate.a > 0.9:
			shown = true
			break
	_check("passage : la carte apparaît", shown)
	var shot := root.get_texture().get_image()
	var rect := Rect2i(main.transition._card.get_global_rect())
	_check("passage : carte au centre du plateau", rect.has_point(Vector2i(520, 56 + 320)))
	_check("passage : texte de la carte dessiné", _bright_fraction(shot.get_region(rect)) > 0.02)


## Part des pixels qui s'écartent nettement de la couleur la plus fréquente (le fond).
func _drawn_fraction(image: Image) -> float:
	var counts := {}
	var step := 3
	var total := 0
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			var key := Color(snappedf(c.r, 0.05), snappedf(c.g, 0.05), snappedf(c.b, 0.05))
			counts[key] = counts.get(key, 0) + 1
			total += 1
	var background: Color = counts.keys()[0]
	for key: Color in counts:
		if counts[key] > counts[background]:
			background = key
	var drawn := 0
	for key: Color in counts:
		if absf(key.r - background.r) + absf(key.g - background.g) + absf(key.b - background.b) > 0.3:
			drawn += counts[key]
	return float(drawn) / maxi(total, 1)


func _bright_fraction(image: Image) -> float:
	var bright := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).get_luminance() > 0.7:
				bright += 1
	return float(bright) / maxi(image.get_width() * image.get_height(), 1)
