extends SceneTree
## Outil de conception : essaie toutes les dispositions d'un balayage et liste les gagnantes.
## Une grande zone gagnante signifie un niveau qui pardonne l'imprécision.
##
## SWEEP=fichier.json godot --headless --path . --fixed-fps 120 -s tests/sweep.gd
## JSON : {"level": id, "seconds": 12, "parts": [{"kind": "plank", "x": [..], "y": [..],
##         "rot": [..], "dir": [..], "channel": [..]}]}

var board: Board


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	board = Board.new()
	root.add_child(board)
	await process_frame
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("SWEEP")))
	var level: Dictionary = {}
	for l: Dictionary in LevelData.all():
		if l.id == spec.level:
			level = l
	var seconds: float = spec.get("seconds", 12.0)
	var combos: Array = [[]]
	for p: Dictionary in spec.parts:
		var next: Array = []
		for base: Array in combos:
			for option: Dictionary in _expand(p):
				next.append(base + [option])
		combos = next
	var wins := 0
	for combo: Array in combos:
		board.load_level(level)
		var ok := true
		for wanted: Dictionary in combo:
			var part := board.place(wanted.kind, wanted.pos)
			for key: String in wanted:
				part.entry[key] = wanted[key]
			part = board.rebuild_part(part)
			ok = ok and board.is_valid(part)
		if not ok:
			continue
		board.start()
		for i in int(seconds * 120):
			await physics_frame
			if board.has_won:
				wins += 1
				print("WIN %.2fs %s" % [i / 120.0, _describe(combo)])
				break
	print("%d gagnantes sur %d" % [wins, combos.size()])
	quit()


func _expand(p: Dictionary) -> Array:
	var out: Array = []
	for x: float in p.x:
		for y: float in p.y:
			for rot: float in p.get("rot", [0.0]):
				for d: float in p.get("dir", [1.0]):
					for ch: float in p.get("channel", [0.0]):
						var e := {"kind": p.kind, "pos": Vector2(x, y), "rot": rot, "dir": int(d)}
						if ch > 0.0:
							e.channel = int(ch)
						out.append(e)
	return out


func _describe(combo: Array) -> String:
	var parts := PackedStringArray()
	for e: Dictionary in combo:
		parts.append("%s(%d,%d r%d d%d c%d)" % [e.kind, e.pos.x, e.pos.y, e.rot, e.dir, e.get("channel", 0)])
	return " ".join(parts)
