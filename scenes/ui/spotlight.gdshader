shader_type canvas_item;
// Tour dim with a soft rounded hole over the shown part (UpgradesTour).

uniform vec2 rect_size = vec2(1280.0, 720.0);
// Hole: x, y, width, height in pixels of this rect.
uniform vec4 hole = vec4(0.0);
uniform float radius = 18.0;
uniform float softness = 28.0;
uniform vec4 dim : source_color = vec4(0.04, 0.047, 0.157, 0.68);

void fragment() {
	vec2 p = UV * rect_size;
	vec2 half_size = hole.zw * 0.5;
	vec2 q = abs(p - (hole.xy + half_size)) - half_size + radius;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	COLOR = vec4(dim.rgb, dim.a * smoothstep(0.0, softness, d));
}
