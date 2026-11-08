class_name Darkness
extends ColorRect
## Voile d'obscurité des niveaux sombres (le grenier) : seuls les faisceaux des lampes de poche,
## les lampes allumées, les bougies et, à l'atelier, un halo autour du pointeur percent le noir.
## Il ne touche pas à la physique : c'est au joueur de chercher le décor.

const MAX_LIGHTS := 16
const DARKNESS := 0.93
## Halo du pointeur à l'atelier, pour explorer le décor avant de lancer.
const CURSOR_RANGE := 110.0
## Voile des vignettes de l'écran de choix : assez léger pour reconnaître le niveau.
const PREVIEW_DARKNESS := 0.55

var board: Board


func _init(p_board: Board) -> void:
	board = p_board
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Board.SIZE
	z_index = 2  # Au-dessus des pièces, à la hauteur des étoiles d'objectif.
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/darkness.gdshader")
	mat.set_shader_parameter("board_size", Board.SIZE)
	mat.set_shader_parameter("darkness", DARKNESS)
	material = mat
	hide()


## Opacité du voile là où rien n'éclaire.
func set_strength(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("darkness", value)


## Lumières de la scène : [{pos, dir, range, half, strength}], `half` absent pour un halo rond.
func sources() -> Array:
	var all: Array = []
	for part in board.parts:
		all.append_array(part.light_sources())
	if not board.running and is_inside_tree() and can_process():
		var mouse := board.get_local_mouse_position()
		if Rect2(Vector2.ZERO, Board.SIZE).has_point(mouse):
			all.append({"pos": mouse, "range": CURSOR_RANGE, "strength": 0.75})
	return all.slice(0, MAX_LIGHTS)


## Part de lumière reçue en un point du plateau (0 : noir complet, 1 : pleine lumière), comme le
## calcule le shader.
func light_at(point: Vector2) -> float:
	var lit := 0.0
	for light: Dictionary in sources():
		var d: Vector2 = point - light.pos
		var dist := d.length()
		var f := 1.0 - smoothstep(light.range * 0.45, light.range, dist)
		if light.has("half"):
			var c := d.normalized().dot(light.dir) if dist > 0.001 else 1.0
			var edge := cos(float(light.half))
			f *= smoothstep(edge - 0.06, edge + 0.03, c)
			f = maxf(f, 1.0 - smoothstep(10.0, 26.0, dist))
		lit = maxf(lit, f * light.get("strength", 1.0))
	return lit


func _process(_delta: float) -> void:
	if visible:
		refresh()


## Envoie les lumières au shader ; appelé à chaque image, et dès le chargement pour les vignettes.
func refresh() -> void:
	var lights := PackedVector4Array()
	var shapes := PackedVector3Array()
	var all := sources()
	for light: Dictionary in all:
		var forward: Vector2 = light.get("dir", Vector2.RIGHT)
		lights.append(Vector4(light.pos.x, light.pos.y, forward.x, forward.y))
		shapes.append(Vector3(light.range, cos(float(light.half)) if light.has("half") else -1.0,
				light.get("strength", 1.0)))
	while lights.size() < MAX_LIGHTS:
		lights.append(Vector4.ZERO)
		shapes.append(Vector3.ZERO)
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("count", all.size())
	mat.set_shader_parameter("lights", lights)
	mat.set_shader_parameter("shapes", shapes)
