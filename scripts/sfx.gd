class_name Sfx
extends Node
## Sons synthétisés par le code : aucun fichier audio à fournir.

const RATE := 22050
const VOICES := 12
const MIN_INTERVAL_MS := 45

## Nombre de demandes par son, y compris celles coupées par la limite de fréquence.
var counts := {}

static var _bank := {}

var _players: Array[AudioStreamPlayer] = []
var _last_played := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if _bank.is_empty():
		_bank = Sfx.build_bank()
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String, volume := 1.0) -> void:
	counts[sound] = counts.get(sound, 0) + 1
	var now := Time.get_ticks_msec()
	if now - _last_played.get(sound, -1000) < MIN_INTERVAL_MS:
		return
	for player in _players:
		if not player.playing:
			_last_played[sound] = now
			player.stream = _bank[sound]
			player.volume_db = linear_to_db(clampf(volume, 0.02, 1.0))
			player.pitch_scale = _rng.randf_range(0.96, 1.04)
			player.play()
			return


static func build_bank() -> Dictionary:
	var bank := {}
	var defs := {
		# Interface
		"place": [[0.07, 520.0, 400.0, 0.7, 40.0, "sine"], [0.02, 0.0, 0.0, 0.2, 90.0, "noise"]],
		"remove": [[0.09, 320.0, 170.0, 0.7, 28.0, "sine"]],
		"tick": [[0.03, 950.0, 950.0, 0.5, 90.0, "sine"]],
		"deny": [[0.16, 140.0, 120.0, 0.5, 8.0, "square"]],
		"start": [[0.14, 330.0, 660.0, 0.7, 10.0, "tri"]],
		"stop": [[0.14, 660.0, 330.0, 0.6, 10.0, "tri"]],
		# Chocs
		"knock": [[0.07, 720.0, 460.0, 0.8, 50.0, "sine"], [0.015, 0.0, 0.0, 0.25, 120.0, "noise"]],
		"wood": [[0.1, 330.0, 220.0, 0.8, 42.0, "tri"], [0.02, 0.0, 0.0, 0.3, 80.0, "noise"]],
		"thud": [[0.24, 115.0, 55.0, 1.0, 17.0, "sine"], [0.05, 0.0, 0.0, 0.3, 40.0, "noise"]],
		# Mécanismes
		"pop": [[0.06, 0.0, 0.0, 1.0, 45.0, "noise"], [0.06, 1300.0, 280.0, 0.6, 35.0, "sine"]],
		"spring": [[0.26, 190.0, 780.0, 0.8, 9.0, "tri"]],
		"plate": [[0.02, 1500.0, 1400.0, 0.5, 90.0, "square"], [0.07, 520.0, 500.0, 0.6, 35.0, "sine"]],
		"cannon": [[0.5, 0.0, 0.0, 1.0, 8.0, "noise"], [0.42, 95.0, 38.0, 1.0, 8.0, "sine"]],
		"lamp": [[0.4, 880.0, 880.0, 0.5, 8.0, "sine"], [0.4, 1320.0, 1320.0, 0.3, 10.0, "sine"]],
		"snip": [[0.04, 0.0, 0.0, 0.8, 70.0, "noise"], [0.05, 2400.0, 1800.0, 0.5, 60.0, "square"]],
		"twang": [[0.34, 150.0, 104.0, 0.8, 13.0, "tri"], [0.2, 300.0, 208.0, 0.3, 20.0, "sine"]],
	}
	for sound: String in defs:
		bank[sound] = _render(defs[sound])
	# Petite fanfare : quatre notes qui se chevauchent.
	var notes: Array = []
	var pitches: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	for i in pitches.size():
		var hold := 0.5 if i == pitches.size() - 1 else 0.2
		notes.append([hold, pitches[i], pitches[i], 0.7, 5.0, "tri", i * 0.13])
	bank["win"] = _render(notes)
	return bank


## Chaque voix : durée, fréquence de départ, d'arrivée, niveau, amortissement, forme, [départ].
static func _render(voices: Array) -> AudioStreamWAV:
	var duration := 0.0
	for v: Array in voices:
		duration = maxf(duration, v[0] + (v[6] if v.size() > 6 else 0.0))
	var mix := PackedFloat32Array()
	mix.resize(int(duration * RATE) + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for v: Array in voices:
		var start := int((v[6] if v.size() > 6 else 0.0) * RATE)
		_add_voice(mix, start, v[0], v[1], v[2], v[3], v[4], v[5], rng)
	var peak := 0.001
	for s in mix:
		peak = maxf(peak, absf(s))
	var bytes := PackedByteArray()
	bytes.resize(mix.size() * 2)
	for i in mix.size():
		bytes.encode_s16(i * 2, int(mix[i] / peak * 0.8 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = bytes
	return wav


static func _add_voice(mix: PackedFloat32Array, start: int, duration: float, f0: float, f1: float,
		level: float, decay: float, shape: String, rng: RandomNumberGenerator) -> void:
	var count := mini(int(duration * RATE), mix.size() - start)
	var phase := 0.0
	var smooth := 0.0
	for i in count:
		var t := float(i) / RATE
		var freq := f0 * pow(f1 / f0, t / duration) if f0 > 0.0 else 0.0
		phase = fposmod(phase + freq / RATE, 1.0)
		var sample := 0.0
		match shape:
			"sine": sample = sin(phase * TAU)
			"square": sample = 1.0 if phase < 0.5 else -1.0
			"tri": sample = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				smooth += 0.35 * (rng.randf_range(-1.0, 1.0) - smooth)
				sample = smooth * 2.0
		# Attaque et fin adoucies pour éviter les clics.
		var edge := minf(minf(t / 0.002, (duration - t) / 0.01), 1.0)
		mix[start + i] += sample * level * exp(-decay * t) * edge
