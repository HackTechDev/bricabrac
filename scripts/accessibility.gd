class_name Accessibility
## Options d'accessibilité, lues par les pièces et les écrans qui en dépendent.
## - Couleurs de canaux adaptées : orange, bleu ciel et violet (palette d'Okabe et Ito), que les
##   formes courantes de daltonisme distinguent, au lieu de rouge, jaune et vert.
## - Animations réduites : pas de balayage entre les niveaux, ni particules, ni écrasement aux
##   chocs ; l'écran titre, le vent et les repères du tutoriel restent immobiles.

const CHANNELS: Array[Color] = [Color("8a94a6"), Color("ff5d5d"), Color("ffc94d"), Color("5dd39e")]
const CHANNELS_SAFE: Array[Color] = [Color("8a94a6"), Color("e69f00"), Color("56b4e9"), Color("cc79a7")]

static var colorblind := false
static var reduce_motion := false


static func apply(p_colorblind: bool, p_reduce_motion: bool) -> void:
	colorblind = p_colorblind
	reduce_motion = p_reduce_motion
	Effects.enabled = not reduce_motion


static func channel_color(channel: int) -> Color:
	return (CHANNELS_SAFE if colorblind else CHANNELS)[channel]
