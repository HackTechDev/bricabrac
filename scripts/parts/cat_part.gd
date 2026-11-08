class_name CatPart
extends Part
## Chat : assis, il guette devant lui. Dès qu'un objet passe en mouvement à portée de vue, il
## bondit dessus en visant l'endroit où l'objet sera à son arrivée. Après chaque saut, il lui faut
## un instant pour se remettre en position. Miroir : côté vers lequel il regarde. Dans le noir du
## grenier, il ne voit que ce qui est éclairé.

const SIZE := Vector2(46, 30)
const SIGHT := 320.0
## Vitesse à partir de laquelle un objet « bouge » aux yeux du chat.
const MIN_SPEED := 60.0
const MAX_LEAP := 950.0
const REST := 1.0
## Lumière qu'il faut à un objet pour que le chat le voie, dans un niveau sombre.
const SEE_LIGHT := 0.3

var body: RigidBody2D
var leaps := 0
var _rest := 0.0
var _prey: RigidBody2D


func _build() -> void:
	body = make_rigid(3.0, 0.05, 0.9)
	body.lock_rotation = true
	add_box(body, SIZE)
	add_visual(body, paint)


func can_flip() -> bool:
	return true


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.7


func impact_sound() -> String:
	return "wood"


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Bondit sur ce qui bouge devant lui, jusqu'à %d px.") % SIGHT)
	if board != null and board.is_dark():
		lines.append(Lang.t("Dans le noir, il ne voit que ce qui est éclairé."))
	return lines


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_instance_valid(body):
		return
	var settled := body.linear_velocity.length() < 15.0
	_rest = _rest - delta if settled else REST
	_prey = _spot()
	if _prey != null and _rest <= 0.0:
		_leap(_prey)


## Objet en mouvement le plus proche, devant le chat et à portée.
func _spot() -> RigidBody2D:
	var best: RigidBody2D = null
	var best_d := SIGHT
	var eye := body.global_position
	for part in board.parts:
		if part == self:
			continue
		for child in part.get_children():
			var other := child as RigidBody2D
			if other == null or other.freeze or other.linear_velocity.length() < MIN_SPEED:
				continue
			var offset := other.global_position - eye
			if offset.x * dir <= 0.0:
				continue
			var d := offset.length()
			if d < best_d and board.is_dark() \
					and board.light_at(board.to_local(other.global_position), [other.get_rid(), body.get_rid()]) < SEE_LIGHT:
				continue
			if d < best_d:
				best = other
				best_d = d
	return best


func _leap(prey: RigidBody2D) -> void:
	var offset := prey.global_position - body.global_position
	var flight := clampf(offset.length() / 450.0, 0.3, 0.7)
	var aim := offset + prey.linear_velocity * flight
	var gravity := body.get_gravity()
	var velocity := aim / flight - gravity * flight / 2.0
	body.linear_velocity = velocity.limit_length(MAX_LEAP)
	_rest = REST
	leaps += 1
	board.sfx.play("meow")


func paint(c: CanvasItem) -> void:
	var fur := Color("e39b4f")
	var d := float(dir)
	var airborne := running and is_instance_valid(body) and body.linear_velocity.length() > 60.0
	# Corps : allongé en plein saut, ramassé au repos.
	var stretch := 1.25 if airborne else 1.0
	var torso := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		torso.append(Vector2(cos(a) * SIZE.x / 2.0 * stretch - 4.0 * d, sin(a) * SIZE.y / 2.0 + 2.0))
	poly(c, torso, fur)
	var head := Vector2(SIZE.x / 2.0 * d, -SIZE.y / 2.0 + 2.0)
	for side: float in [-1.0, 1.0]:
		poly(c, PackedVector2Array([head + Vector2(side * 9.0 - 2.0, -6.0), head + Vector2(side * 9.0 + 2.0 * side, -20.0),
				head + Vector2(side * 2.0, -9.0)]), fur)
	c.draw_circle(head, 12.0, fur)
	c.draw_arc(head, 12.0, 0.0, TAU, 20, INK, 2.0)
	var alert := _prey != null or airborne
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(4.0 * d + side * 4.5, -2.0)
		if alert:
			c.draw_circle(eye, 3.0, Color("f4e46a"))
			c.draw_line(eye + Vector2(0, -2.5), eye + Vector2(0, 2.5), INK, 1.5)
		else:
			c.draw_line(eye + Vector2(-2.5, 0), eye + Vector2(2.5, 0), INK, 1.5)
	c.draw_circle(head + Vector2(9.0 * d, 3.0), 1.8, Color("e0566b"))
	var tail := PackedVector2Array()
	var base := Vector2(-SIZE.x / 2.0 * d - 2.0 * d, 4.0)
	var wag := sin(anim * (10.0 if alert else 2.5)) * (6.0 if alert else 3.0)
	for i in 8:
		var t := i / 7.0
		tail.append(base + Vector2(-d * t * 18.0, -t * 24.0 + sin(t * PI) * wag))
	c.draw_polyline(tail, fur, 5.0)
	c.draw_polyline(tail, INK, 1.0)
