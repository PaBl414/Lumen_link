shader_type canvas_item;
render_mode unshaded;
uniform float charge : hint_range(0.0, 1.0) = 0.0;
uniform float warning : hint_range(0.0, 1.0) = 0.0;
uniform float motion = 1.0;
void fragment() {
	vec4 base = COLOR;
	float pulse = 0.92 + 0.08 * sin(TIME * 5.0 * motion);
	vec3 lit = base.rgb * (1.0 + charge * 0.18);
	lit = mix(lit, lit * vec3(1.15, 0.88, 0.68) * pulse, warning * 0.65);
	COLOR = vec4(lit, base.a);
}
