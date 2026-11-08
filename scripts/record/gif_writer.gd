class_name GifWriter
extends RefCounted
## Encodeur GIF animé, sans dépendance. Palette fixe de 252 couleurs (6 rouges × 7 verts × 6 bleus),
## suffisante pour les aplats du jeu. Chaque image n'encode que le rectangle qui a changé depuis la
## précédente, ce qui garde l'encodage rapide et le fichier léger.

const LEVELS_R := 6
const LEVELS_G := 7
const LEVELS_B := 6

var width := 0
var height := 0
var frames := 0
var _out := PackedByteArray()
var _previous := PackedByteArray()
var _lut_r := PackedInt32Array()
var _lut_g := PackedInt32Array()
var _lut_b := PackedInt32Array()


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	for v in 256:
		_lut_r.append(roundi(v / 255.0 * (LEVELS_R - 1)) * LEVELS_G * LEVELS_B)
		_lut_g.append(roundi(v / 255.0 * (LEVELS_G - 1)) * LEVELS_B)
		_lut_b.append(roundi(v / 255.0 * (LEVELS_B - 1)))
	_out.append_array("GIF89a".to_ascii_buffer())
	_u16(width)
	_u16(height)
	_out.append(0xF7)  # Palette globale de 256 entrées.
	_out.append(0)
	_out.append(0)
	for i in 256:
		var r := i / (LEVELS_G * LEVELS_B)
		var g := (i / LEVELS_B) % LEVELS_G
		var b := i % LEVELS_B
		if i >= LEVELS_R * LEVELS_G * LEVELS_B:
			r = 0
			g = 0
			b = 0
		_out.append(roundi(r * 255.0 / (LEVELS_R - 1)))
		_out.append(roundi(g * 255.0 / (LEVELS_G - 1)))
		_out.append(roundi(b * 255.0 / (LEVELS_B - 1)))
	# Bouclage infini.
	_out.append_array(PackedByteArray([0x21, 0xFF, 0x0B]))
	_out.append_array("NETSCAPE2.0".to_ascii_buffer())
	_out.append_array(PackedByteArray([3, 1, 0, 0, 0]))


## Ajoute une image (redimensionnée si besoin) affichée `delay_cs` centièmes de seconde.
func add_frame(image: Image, delay_cs: int) -> void:
	var img := image.duplicate() as Image
	img.convert(Image.FORMAT_RGB8)
	if img.get_width() != width or img.get_height() != height:
		img.resize(width, height, Image.INTERPOLATE_BILINEAR)
	var indices := _quantize(img.get_data())
	var box := _changed_box(indices)
	_previous = indices
	# Contrôle graphique : délai, pas d'effacement entre les images.
	_out.append_array(PackedByteArray([0x21, 0xF9, 4, 0x04]))
	_u16(delay_cs)
	_out.append_array(PackedByteArray([0, 0]))
	_out.append(0x2C)
	_u16(box.position.x)
	_u16(box.position.y)
	_u16(box.size.x)
	_u16(box.size.y)
	_out.append(0)
	var pixels := PackedByteArray()
	pixels.resize(box.size.x * box.size.y)
	for y in box.size.y:
		var start := (box.position.y + y) * width + box.position.x
		var row := indices.slice(start, start + box.size.x)
		for x in box.size.x:
			pixels[y * box.size.x + x] = row[x]
	_out.append(8)
	var data := _lzw(pixels)
	var i := 0
	while i < data.size():
		var n := mini(255, data.size() - i)
		_out.append(n)
		_out.append_array(data.slice(i, i + n))
		i += n
	_out.append(0)
	frames += 1


func finish() -> PackedByteArray:
	_out.append(0x3B)
	return _out


func _quantize(rgb: PackedByteArray) -> PackedByteArray:
	var count := rgb.size() / 3
	var indices := PackedByteArray()
	indices.resize(count)
	for i in count:
		indices[i] = _lut_r[rgb[i * 3]] + _lut_g[rgb[i * 3 + 1]] + _lut_b[rgb[i * 3 + 2]]
	return indices


## Plus petit rectangle qui diffère de l'image précédente (au moins 1×1).
func _changed_box(indices: PackedByteArray) -> Rect2i:
	if _previous.is_empty():
		return Rect2i(0, 0, width, height)
	var top := -1
	var bottom := -1
	for y in height:
		var a := indices.slice(y * width, (y + 1) * width)
		if a != _previous.slice(y * width, (y + 1) * width):
			if top < 0:
				top = y
			bottom = y
	if top < 0:
		return Rect2i(0, 0, 1, 1)
	var left := width
	var right := 0
	for y in range(top, bottom + 1):
		var base := y * width
		var x := 0
		while x < left and indices[base + x] == _previous[base + x]:
			x += 1
		left = mini(left, x)
		x = width - 1
		while x > right and indices[base + x] == _previous[base + x]:
			x -= 1
		right = maxi(right, x)
	right = maxi(right, left)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


## Compression LZW du format GIF, codes de 9 à 12 bits (même logique que l'encodeur historique :
## la taille des codes augmente juste après l'écriture qui suit le passage d'une puissance de 2).
var _acc := 0
var _acc_bits := 0
var _code_size := 9
var _free := 258
var _clearing := false
var _buf := PackedByteArray()


func _lzw(pixels: PackedByteArray) -> PackedByteArray:
	_buf = PackedByteArray()
	_acc = 0
	_acc_bits = 0
	_code_size = 9
	_free = 258
	_clearing = false
	var table := {}
	_output(256)
	if pixels.is_empty():
		pixels = PackedByteArray([0])
	var prefix := int(pixels[0])
	for i in range(1, pixels.size()):
		var c := int(pixels[i])
		var key := (c << 12) | prefix
		var found: Variant = table.get(key)
		if found != null:
			prefix = found
			continue
		_output(prefix)
		prefix = c
		if _free < 4096:
			table[key] = _free
			_free += 1
		else:
			table.clear()
			_free = 258
			_clearing = true
			_output(256)
	_output(prefix)
	_output(257)
	if _acc_bits > 0:
		_buf.append(_acc & 0xFF)
	return _buf


func _output(code: int) -> void:
	_acc |= code << _acc_bits
	_acc_bits += _code_size
	while _acc_bits >= 8:
		_buf.append(_acc & 0xFF)
		_acc >>= 8
		_acc_bits -= 8
	if _clearing:
		_code_size = 9
		_clearing = false
	elif _free > (1 << _code_size) - 1 and _code_size < 12:
		_code_size += 1


func _u16(v: int) -> void:
	_out.append(v & 0xFF)
	_out.append((v >> 8) & 0xFF)
