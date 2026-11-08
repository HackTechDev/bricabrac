class_name TimerPart
extends Part
## Minuterie : démarre au lancement et allume son canal une fois le délai écoulé.
## R ou la molette règlent le délai.

const SIZE := Vector2(52, 52)
const DEFAULT_DELAY := 2.0

var elapsed := 0.0
var _fired := false


func _build() -> void:
	var body := make_static()
	add_box(body, SIZE)
	add_visual(body, paint)


func _physics_process(delta: float) -> void:
	if _fired:
		return
	elapsed += delta
	if elapsed >= delay():
		_fired = true
		board.sfx.play("tick")
		board.set_channel(channel, true)


func delay() -> float:
	return entry.get("delay", DEFAULT_DELAY)


func setting() -> Dictionary:
	return {"key": "delay", "step": 0.5, "min": 0.5, "max": 15.0, "default": DEFAULT_DELAY,
			"label": Lang.t("Délai (R)")}


func channel_range() -> Vector2i:
	return Vector2i(1, 3)


func is_animated() -> bool:
	return true


func icon_scale() -> float:
	return 0.7


func describe() -> PackedStringArray:
	var lines := super()
	lines.append(Lang.t("Délai : %.1f s après le lancement") % delay())
	return lines


func paint(c: CanvasItem) -> void:
	box(c, Rect2(-SIZE / 2.0, SIZE), Color("47525f"))
	var center := Vector2(0, -4)
	c.draw_circle(center, 17.0, Color("f4ecd8"))
	c.draw_arc(center, 17.0, 0.0, TAU, 28, INK, 2.0)
	var left := clampf(1.0 - elapsed / delay(), 0.0, 1.0) if running else 1.0
	if left > 0.0:
		c.draw_arc(center, 11.0, -PI / 2.0, -PI / 2.0 + TAU * left, 28, CHANNEL_COLORS[channel], 6.0)
	c.draw_line(center, center + Vector2.UP.rotated(TAU * (1.0 - left)) * 14.0, INK, 2.0)
	var label := Lang.t("%.1f s") % (maxf(delay() - elapsed, 0.0) if running else delay())
	c.draw_string(ThemeDB.fallback_font, Vector2(-SIZE.x / 2.0, SIZE.y / 2.0 - 3.0), label,
			HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 11, Color.WHITE)
	paint_channel(c, Vector2(SIZE.x / 2.0 - 8.0, -SIZE.y / 2.0 + 8.0))
