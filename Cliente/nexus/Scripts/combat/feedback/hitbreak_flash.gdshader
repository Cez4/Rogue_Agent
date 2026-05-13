shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.45, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec3 flashed = mix(base.rgb, flash_color.rgb, flash_amount * flash_color.a);
	COLOR = vec4(flashed, base.a);
}
