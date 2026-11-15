shader_type canvas_item;
render_mode unshaded;
uniform sampler2D grain_texture : repeat_enable, filter_nearest;
uniform float grain_strength : hint_range(0.0, 0.1) = 0.025;
void fragment() {
	vec4 base = COLOR;
	float grain = texture(grain_texture, UV * vec2(10.0, 5.625)).r - 0.5;
	COLOR = vec4(base.rgb + grain * grain_strength, base.a);
}
