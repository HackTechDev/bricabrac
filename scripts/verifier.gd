class_name Verifier
extends Node
## Rejoue la solution d'un niveau importé sur un plateau invisible, dans son propre monde
## physique : le niveau n'est accepté que si cette solution respecte l'inventaire et gagne.

const TIMEOUT := 30.0

var busy := false


## Chaîne vide si la solution gagne, sinon la raison du refus.
func verify(level: Dictionary) -> String:
	busy = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(Board.SIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var board := Board.new()
	viewport.add_child(board)
	board.sfx.silent = true
	board.load_level(level.duplicate(true))
	var reason := ""
	for part: Part in board.apply_layout(level.get("solution", [])):
		if board.remaining(part.kind) < 0:
			reason = "La solution utilise plus de pièces que l'inventaire n'en offre."
		elif not part is RopePart and not board.is_valid(part):
			reason = "La solution pose une pièce là où elle n'a pas la place."
	if reason == "":
		board.start()
		var ticks := int(TIMEOUT * Engine.physics_ticks_per_second)
		for i in ticks:
			await get_tree().physics_frame
			if board.has_won:
				break
		if not board.has_won:
			reason = "La solution fournie ne gagne pas : le niveau est refusé."
	viewport.queue_free()
	busy = false
	return reason
