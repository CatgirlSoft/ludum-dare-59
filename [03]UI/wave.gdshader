shader_type canvas_item;

uniform sampler2D samples;
uniform int sample_count = 100;
uniform vec4 line_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float line_thickness : hint_range(0.001, 0.05) = 0.08;

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
	float noise = cos(noise_uv.x + (TIME * 4.0) * random(noise_uv)) * 2.0;
	float noise_offset = noise;
	float noise_uv_y = 0.5 - (curve_y + noise) * 0.5;
	
	float dist = UV.y - curve_uv_y;

	float in_spread = step(0.0, dist * sign(noise_offset)) * step(abs(dist), abs(noise_offset) * 0.5);

    float spread_alpha = in_spread * (1.0 - abs(dist) / (abs(noise_offset) * 0.05));
	float dist_noise = abs(UV.y - noise_uv_y);

	float alpha_clean = smoothstep(line_thickness, line_thickness * 0.5, abs(dist));
	float alpha_noise = smoothstep(line_thickness, line_thickness * 0.5, abs(dist_noise));
	float alpha1 = max(alpha_clean, spread_alpha);
	float alpha = max(alpha1, alpha_noise * 0.5);

	COLOR = vec4(line_color.rgb, line_color.a * alpha);
}