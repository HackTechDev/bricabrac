extends SceneTree
## Coût d'un pas de simulation selon le nombre d'objets, avec ou sans vent et cordes.
## godot --headless --path . --fixed-fps 120 -s tests/bench_perf.gd
## Les corps ne s'endorment jamais (can_sleep = false), et le vent comme la corde lancent des
## rayons à chaque pas : ce banc mesure ce que cela coûte quand les objets se multiplient.

const STEPS := 240
const COUNTS: Array[int] = [25, 100, 200]

var board: Board


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	board = Board.new()
	board.position = Vector2(0, 56)
	root.add_child(board)
	await process_frame
	print("objets  scène           ms/pas   (budget à 120 pas/s : 8,3 ms)")
	for count in COUNTS:
		for scene: String in ["billes", "billes + vent", "billes + cordes"]:
			var ms := await _measure(count, scene)
			print("%6d  %-15s %7.2f" % [count, scene, ms])
	board.free()
	await process_frame
	OS.delay_msec(150)
	quit()


func _measure(count: int, scene: String) -> float:
	var fixed: Array = []
	var columns := 20
	for i in count:
		var pos := Vector2(40 + (i % columns) * 48, 60 + floori(i / float(columns)) * 44)
		fixed.append({"kind": "ball_bouncy" if i % 2 else "ball", "id": "b%d" % i, "pos": pos})
	# Des étagères pour que les billes se touchent et roulent, comme dans une vraie machine.
	for row in 4:
		fixed.append({"kind": "plank", "pos": Vector2(520, 420 + row * 50), "len": 900.0,
				"rot": 3.0 if row % 2 else -3.0, "locked": true})
	if scene.contains("cordes"):
		for i in range(0, count - 1, 2):
			fixed.append({"kind": "rope", "from": "b%d" % i, "from_off": Vector2.ZERO, "via": [],
					"to": "b%d" % (i + 1), "to_off": Vector2.ZERO})
	var extra := {"wind": Vector2(120, 0)} if scene.contains("vent") else {}
	var level := {"fixed": fixed, "inventory": {}}
	level.merge(extra)
	board.load_level(level)
	board.start()
	await physics_frame
	var start := Time.get_ticks_usec()
	for i in STEPS:
		await physics_frame
	var ms := (Time.get_ticks_usec() - start) / 1000.0 / STEPS
	board.stop()
	return ms
