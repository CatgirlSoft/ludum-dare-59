shader_type canvas_item;

uniform sampler2D samples;
uniform int sample_count = 100;
uniform vec4 line_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float line_thickness : hint_range(0.001, 0.05) = 0.008;

float random (vec2 uv) {
	return fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	float aspect = 1.0 / TEXTURE_PIXEL_SIZE.x * TEXTURE_PIXEL_SIZE.y;

	float sample_val = texture(samples, vec2(UV.x, 0.0)).r;
	float curve_y = sample_val * 2.0 - 1.0;
	float curve_uv_y = 0.5 - curve_y * 0.5;

	vec2 noise_uv = vec2(UV.x * aspect * 25.0, UV.y);
	float noise = cos(noise_uv.x + TIME * random(noise_uv)) * 0.05;
	float noise_uv_y = 0.5 - (curve_y + noise) * 0.5;
	
	float dist_clean = abs(UV.y - curve_uv_y);
	float dist_noise = abs(UV.y - noise_uv_y);

	float alpha_clean = smoothstep(line_thickness, line_thickness * 0.5, dist_clean);
	float alpha_noise = smoothstep(line_thickness, line_thickness * 0.5, dist_noise);
	float alpha = max(alpha_clean, alpha_noise);

	COLOR = vec4(line_color.rgb, line_color.a * alpha);
}