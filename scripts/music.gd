class_name Music
extends AudioStreamPlayer
## Musique d'atelier discrète : une boîte à musique sur une basse et des nappes douces, en boucle
## de 20 secondes, composée par le code. Elle se calcule en arrière-plan au premier lancement.

const RATE := 11025
const BEAT := 0.625
const BAR := BEAT * 4.0
## La mineur, fa, do, sol, puis la mineur, ré mineur, fa, mi : fondamentale et accord (Hz).
const CHORDS: Array = [
	[110.0, [220.0, 261.63, 329.63]],
	[87.31, [174.61, 220.0, 261.63]],
	[130.81, [196.0, 261.63, 329.63]],
	[98.0, [196.0, 246.94, 293.66]],
	[110.0, [220.0, 261.63, 329.63]],
	[73.42, [174.61, 220.0, 293.66]],
	[87.31, [174.61, 220.0, 261.63]],
	[82.41, [207.65, 246.94, 329.63]],
]
## Motif de la boîte à musique, en croches : indice de note de l'accord (une octave plus haut),
## -1 pour un silence.
const PATTERN: Array[int] = [0, 2, 1, 2, -1, 2, 1, 0]

static var _stream: AudioStreamWAV
static var _thread: Thread


func _ready() -> void:
	Sfx.ensure_buses()
	bus = Sfx.BUS_MUSIC
	volume_db = -6.0
	# Sans écran (tests), pas de musique : son calcul ralentirait chaque lancement.
	if DisplayServer.get_name() == "headless":
		return
	if _stream != null:
		_start()
	elif not OS.has_feature("threads"):
		# Navigateur sans fils d'exécution : composée sur le fil principal, une fois l'écran
		# affiché, au prix d'un court arrêt.
		get_tree().create_timer(0.5).timeout.connect(_compose_now)
	elif _thread == null:
		_thread = Thread.new()
		_thread.start(Music._compose)
		set_process(true)


func _process(_delta: float) -> void:
	if _thread != null and not _thread.is_alive():
		_stream = _thread.wait_to_finish()
		_thread = null
	if _stream != null:
		set_process(false)
		_start()


func _exit_tree() -> void:
	stop()
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	# Libérée avec le lecteur, pour que Godot ne la compte pas comme une fuite en quittant.
	_stream = null


func _compose_now() -> void:
	if _stream == null:
		_stream = Music._compose()
	if is_inside_tree():
		_start()


func _start() -> void:
	stream = _stream
	play()


static func _compose() -> AudioStreamWAV:
	var length := int(BAR * CHORDS.size() * RATE)
	var mix := PackedFloat32Array()
	mix.resize(length)
	for bar in CHORDS.size():
		var root: float = CHORDS[bar][0]
		var notes: Array = CHORDS[bar][1]
		var start := bar * BAR
		_note(mix, start, BAR * 0.9, root, 0.45, 2.0, "sine")
		_note(mix, start + BEAT * 2.0, BAR * 0.45, root, 0.3, 3.0, "sine")
		for f: float in notes:
			_note(mix, start, BAR, f, 0.07, 0.5, "tri")
		for step in PATTERN.size():
			var index := PATTERN[step]
			if index >= 0 and not (bar % 4 == 3 and step >= 6):
				_note(mix, start + step * BEAT / 2.0, 0.9, notes[index] * 2.0, 0.22, 5.0, "bell")
	var wav := Sfx._to_wav(mix, 0.6, RATE)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = length
	return wav


static func _note(mix: PackedFloat32Array, start: float, duration: float, freq: float, level: float,
		decay: float, shape: String) -> void:
	var first := int(start * RATE)
	var count := int(duration * RATE)
	var length := int(BAR * CHORDS.size() * RATE)
	for i in count:
		var t := float(i) / RATE
		var phase := fposmod(t * freq, 1.0)
		var sample: float
		match shape:
			"tri": sample = 4.0 * absf(phase - 0.5) - 1.0
			"bell": sample = sin(phase * TAU) + 0.3 * sin(phase * TAU * 3.0) * exp(-8.0 * t)
			_: sample = sin(phase * TAU)
		# Les notes qui dépassent la fin de la boucle reprennent au début : pas de couture.
		var attack := minf(t / (0.15 if shape == "tri" else 0.004), 1.0)
		var release := minf((duration - t) / 0.05, 1.0)
		mix[(first + i) % length] += sample * level * exp(-decay * t) * attack * release
