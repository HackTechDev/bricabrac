class_name AviWriter
extends RefCounted
## Vidéo AVI au format MJPEG : chaque image est un JPEG, rangé dans un conteneur AVI avec son
## index. Lisible par les lecteurs courants (VLC, navigateurs via conversion, ffmpeg).

var width := 0
var height := 0
var fps := 30
var _frames: Array[PackedByteArray] = []


func _init(p_width: int, p_height: int, p_fps: int) -> void:
	width = p_width
	height = p_height
	fps = p_fps


func add_frame(image: Image, quality := 0.85) -> void:
	var img := image.duplicate() as Image
	img.convert(Image.FORMAT_RGB8)
	if img.get_width() != width or img.get_height() != height:
		img.resize(width, height, Image.INTERPOLATE_BILINEAR)
	_frames.append(img.save_jpg_to_buffer(quality))


func frame_count() -> int:
	return _frames.size()


func finish() -> PackedByteArray:
	var biggest := 0
	for f in _frames:
		biggest = maxi(biggest, f.size())
	var movi := StreamPeerBuffer.new()
	var index := StreamPeerBuffer.new()
	var offset := 4  # Les décalages de l'index partent du mot « movi ».
	for f in _frames:
		var padded := f.size() + (f.size() & 1)
		movi.put_data("00dc".to_ascii_buffer())
		movi.put_u32(f.size())
		movi.put_data(f)
		if f.size() & 1:
			movi.put_u8(0)
		index.put_data("00dc".to_ascii_buffer())
		index.put_u32(0x10)
		index.put_u32(offset)
		index.put_u32(f.size())
		offset += 8 + padded

	var avih := StreamPeerBuffer.new()
	avih.put_u32(1000000 / fps)
	avih.put_u32(biggest * fps)
	avih.put_u32(0)
	avih.put_u32(0x10)
	avih.put_u32(_frames.size())
	avih.put_u32(0)
	avih.put_u32(1)
	avih.put_u32(biggest)
	avih.put_u32(width)
	avih.put_u32(height)
	for i in 4:
		avih.put_u32(0)

	var strh := StreamPeerBuffer.new()
	strh.put_data("vidsMJPG".to_ascii_buffer())
	strh.put_u32(0)
	strh.put_u16(0)
	strh.put_u16(0)
	strh.put_u32(0)
	strh.put_u32(1)
	strh.put_u32(fps)
	strh.put_u32(0)
	strh.put_u32(_frames.size())
	strh.put_u32(biggest)
	strh.put_u32(0xFFFFFFFF)
	strh.put_u32(0)
	strh.put_u16(0)
	strh.put_u16(0)
	strh.put_u16(width)
	strh.put_u16(height)

	var strf := StreamPeerBuffer.new()
	strf.put_u32(40)
	strf.put_32(width)
	strf.put_32(height)
	strf.put_u16(1)
	strf.put_u16(24)
	strf.put_data("MJPG".to_ascii_buffer())
	strf.put_u32(width * height * 3)
	for i in 4:
		strf.put_u32(0)

	var strl := _list("strl", _chunk("strh", strh.data_array) + _chunk("strf", strf.data_array))
	var hdrl := _list("hdrl", _chunk("avih", avih.data_array) + strl)
	var body := "AVI ".to_ascii_buffer() + hdrl + _list("movi", movi.data_array) + _chunk("idx1", index.data_array)
	return "RIFF".to_ascii_buffer() + _u32(body.size()) + body


static func _chunk(id: String, data: PackedByteArray) -> PackedByteArray:
	var out := id.to_ascii_buffer() + _u32(data.size()) + data
	if data.size() & 1:
		out.append(0)
	return out


static func _list(kind: String, data: PackedByteArray) -> PackedByteArray:
	return "LIST".to_ascii_buffer() + _u32(data.size() + 4) + kind.to_ascii_buffer() + data


static func _u32(v: int) -> PackedByteArray:
	return PackedByteArray([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
