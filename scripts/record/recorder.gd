class_name Recorder
extends Node
## Filme une zone de l'écran pendant une relecture et l'enregistre en GIF animé (demi-taille,
## 12,5 images par seconde) ou en vidéo AVI MJPEG (taille réelle, 30 images par seconde).
## Les fichiers vont dans le dossier « enregistrements » des données du jeu.

const DIR := "user://enregistrements"
const GIF_INTERVAL := 0.08
const VIDEO_FPS := 30
const MAX_SECONDS := 20.0

## "" (rien), "gif" ou "video".
var mode := ""
var region := Rect2i()
var frames := 0
var _gif: GifWriter
var _avi: AviWriter
var _clock := 0.0
var _elapsed := 0.0


func start(p_mode: String, p_region: Rect2i) -> void:
	mode = p_mode
	region = p_region
	frames = 0
	_clock = 0.0
	_elapsed = 0.0
	if mode == "gif":
		_gif = GifWriter.new(region.size.x / 2, region.size.y / 2)
	else:
		_avi = AviWriter.new(region.size.x, region.size.y, VIDEO_FPS)
	_capture()


func is_recording() -> bool:
	return mode != ""


func _interval() -> float:
	return GIF_INTERVAL if mode == "gif" else 1.0 / VIDEO_FPS


func _process(delta: float) -> void:
	if mode == "" or _elapsed >= MAX_SECONDS:
		return
	_elapsed += delta
	_clock += delta
	while _clock >= _interval():
		_clock -= _interval()
		_capture()


func _capture() -> void:
	var shot: Image = null
	if DisplayServer.get_name() != "headless":
		shot = get_viewport().get_texture().get_image()
	var img: Image
	if shot == null or shot.is_empty():
		# Sans rendu (tests sans écran) : une image unie garde la cadence du fichier.
		img = Image.create(region.size.x, region.size.y, false, Image.FORMAT_RGB8)
	else:
		img = shot.get_region(region)
	if mode == "gif":
		_gif.add_frame(img, roundi(GIF_INTERVAL * 100.0))
	else:
		_avi.add_frame(img)
	frames += 1


## Arrête et écrit le fichier ; renvoie son chemin complet, ou "" en cas d'échec.
func stop() -> String:
	if mode == "":
		return ""
	DirAccess.make_dir_recursive_absolute(DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/bricabrac_%s.%s" % [DIR, stamp, "gif" if mode == "gif" else "avi"]
	var data := _gif.finish() if mode == "gif" else _avi.finish()
	mode = ""
	_gif = null
	_avi = null
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_buffer(data)
	file.close()
	return ProjectSettings.globalize_path(path)
