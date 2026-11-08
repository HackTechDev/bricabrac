class_name LevelTransition
extends Control
## Passage d'un niveau à l'autre. Le nouveau niveau est chargé tout de suite ; par-dessus, une
## photo de l'écran précédent s'efface en balayage vers la droite, derrière une bande à la couleur
## du nouveau monde, puis une carte annonce le monde et le nom du niveau.
## Elle ne prend jamais la souris : on peut commencer à construire pendant l'animation.

const WIPE := 0.45
const CARD_IN := 0.15
const CARD_HOLD := 0.9
const CARD_OUT := 0.35
const BAND := 26.0

var _clip: Control
var _shot: TextureRect
var _band: ColorRect
var _card: PanelContainer
var _world: Label
var _name: Label
var _tween: Tween


func _init() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50  # Au-dessus des marques d'objectif du plateau, sous l'écran titre.
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_shot = TextureRect.new()
	_shot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_shot)
	_band = ColorRect.new()
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_band)

	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18.0)
	style.border_color = Part.GOLD
	style.set_border_width_all(2)
	_card.add_theme_stylebox_override("panel", style)
	add_child(_card)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)
	_world = Label.new()
	_world.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	box.add_child(_world)
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 30)
	_name.add_theme_color_override("font_color", Part.GOLD)
	box.add_child(_name)
	hide()


## Photo de l'écran actuel, à prendre avant de charger le niveau suivant ; null sans affichage.
func snapshot() -> Texture2D:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return null
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


## Joue le passage : balayage de la photo s'il y en a une, puis carte du niveau.
## `board_rect` : zone du plateau, où la carte se centre.
func play(shot: Texture2D, world: String, level_name: String, color: Color, board_rect: Rect2) -> void:
	if _tween != null:
		_tween.kill()
	show()
	_world.text = world
	_name.text = level_name
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(color.lightened(0.08), 0.94)
	_card.reset_size()
	_card.position = board_rect.get_center() - _card.get_combined_minimum_size() / 2.0
	_card.modulate.a = 0.0
	_band.color = color.lightened(0.25)
	_tween = create_tween()
	if shot != null:
		_shot.texture = shot
		_clip.visible = true
		_band.visible = true
		_set_wipe(0.0)
		_tween.tween_method(_set_wipe, 0.0, 1.0, WIPE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		_clip.visible = false
		_band.visible = false
	_tween.tween_property(_card, "modulate:a", 1.0, CARD_IN)
	_tween.tween_interval(CARD_HOLD)
	_tween.tween_property(_card, "modulate:a", 0.0, CARD_OUT)
	_tween.tween_callback(_done)


func is_playing() -> bool:
	return visible


## Balayage : `t` de 0 (photo entière) à 1 (photo disparue).
func _set_wipe(t: float) -> void:
	var x := t * (size.x + BAND)
	_clip.position = Vector2(x, 0)
	_clip.size = Vector2(maxf(size.x - x, 0.0), size.y)
	_shot.position = Vector2(-x, 0)
	_band.position = Vector2(x - BAND, 0)
	_band.size = Vector2(BAND, size.y)
	if t >= 1.0:
		_clip.visible = false
		_band.visible = false
		_shot.texture = null


func _done() -> void:
	_shot.texture = null
	hide()
