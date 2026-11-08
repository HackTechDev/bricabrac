class_name BallPart
extends Part
## Billes : même forme, comportements très différents selon la masse et le rebond.

const SPECS := {
	"ball": {"r": 16.0, "mass": 1.5, "bounce": 0.35, "color": Color("4da3ff")},
	"ball_bouncy": {"r": 15.0, "mass": 0.8, "bounce": 0.85, "color": Color("ff7ac6")},
	"ball_heavy": {"r": 22.0, "mass": 6.0, "bounce": 0.1, "color": Color("59636f")},
}

var body: RigidBody2D


func _build() -> void:
	var s: Dictionary = SPECS[kind]
	body = make_rigid(s.mass, s.bounce)
	add_disc(body, s.r)
	add_visual(body, paint)
	if entry.has("vel"):
		body.linear_velocity = entry.vel


func is_metal() -> bool:
	return kind != "ball_bouncy"


func impact_sound() -> String:
	return "thud" if kind == "ball_heavy" else "knock"


func paint(c: CanvasItem) -> void:
	var s: Dictionary = SPECS[kind]
	c.draw_circle(Vector2.ZERO, s.r, s.color)
	c.draw_arc(Vector2.ZERO, s.r, 0.0, TAU, 32, INK, 2.0)
	# Le trait rend la rotation visible.
	c.draw_line(Vector2(-s.r * 0.6, 0), Vector2(s.r * 0.6, 0), INK, 2.0)
	c.draw_circle(Vector2(-s.r * 0.3, -s.r * 0.4), s.r * 0.16, Color(1, 1, 1, 0.75))
