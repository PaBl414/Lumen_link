shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float motion = 1.0;
void fragment() {
	vec4 base = COLOR;
	float glint = 0.9 + 0.1 * sin(UV.x * 60.0 - TIME * 2.5 * motion);
	COLOR = vec4(base.rgb * glint, base.a);
}
