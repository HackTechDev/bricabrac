shader_type canvas_item;
// Obscurité du grenier : un voile sombre que percent les faisceaux et les halos.
// lights[i] : position (xy) et direction (zw) ; shapes[i] : portée, cosinus de la demi-ouverture
// (-1 pour un halo rond), intensité.

const int MAX_LIGHTS = 16;
uniform vec2 board_size = vec2(1040.0, 640.0);
uniform float darkness = 0.85;
uniform int count = 0;
uniform vec4 lights[MAX_LIGHTS];
uniform vec3 shapes[MAX_LIGHTS];

void fragment() {
	vec2 p = UV * board_size;
	float lit = 0.0;
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= count) {
			break;
		}
		vec2 d = p - lights[i].xy;
		float dist = length(d);
		float range = shapes[i].x;
		float f = 1.0 - smoothstep(range * 0.45, range, dist);
		if (shapes[i].y > -1.0) {
			float c = dot(d / max(dist, 0.001), lights[i].zw);
			f *= smoothstep(shapes[i].y - 0.06, shapes[i].y + 0.03, c);
			f = max(f, 1.0 - smoothstep(10.0, 26.0, dist));
		}
		lit = max(lit, f * shapes[i].z);
	}
	COLOR = vec4(0.02, 0.02, 0.05, darkness * (1.0 - lit));
}
