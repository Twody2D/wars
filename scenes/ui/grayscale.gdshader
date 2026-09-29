shader_type canvas_item;
// Greyed-out picture of a bought shop item (the mockup's CSS grayscale(1)).

uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float grey = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(grey), amount);
}
