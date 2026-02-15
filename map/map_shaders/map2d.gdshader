shader_type canvas_item;

uniform sampler2D lookup_image: source_color, filter_nearest;
uniform sampler2D color_map_image: source_color, filter_nearest;
uniform sampler2D province_border_image: source_color, filter_nearest;

void fragment() {
	// Variables
	// Must match MapMode.SECONDARY_OFFSET (150) in map_mode.gd
	float normalized_offset = 150.0 / float(textureSize(color_map_image,0).y);
	float checkers_width = 10.0;
	float texture_width = float(textureSize(lookup_image,0).x);
	float texture_height = float(textureSize(lookup_image,0).y);
	int checkers_pattern = int(mod(floor(UV.x * texture_width / checkers_width) + floor(UV.y * texture_height / checkers_width), 2.0));

	// Textures
	vec3 lookup_texture = texture(lookup_image, UV).rgb;
	vec3 province_border_texture = texture(province_border_image, UV).rgb;

	// Scale Y coordinate: lookup encodes 256 rows, but color map may be taller
	float y_scale = 256.0 / float(textureSize(color_map_image, 0).y);
	vec2 color_map_uv = vec2(lookup_texture.r, lookup_texture.g * y_scale);

	vec4 map_mode_primary = texture(color_map_image, color_map_uv);
	vec4 map_mode_secondary = texture(color_map_image, color_map_uv + vec2(0.0, normalized_offset));
	// 2.0 * normalized_offset = MapMode.HIGHLIGHT_OFFSET (300) in map_mode.gd
	vec4 selected_color = texture(color_map_image, color_map_uv + vec2(0.0, 2.0 * normalized_offset));
	
	// Set checkers
	vec4 final_color = mix(map_mode_primary,map_mode_secondary,float(checkers_pattern));

	// Darken province borders
	float is_border = 1.0 - province_border_texture.r;
	final_color.rgb = mix(final_color.rgb, final_color.rgb * 0.9, is_border);

	// Selection edge highlighting (green = province border, white = territory border)
	// if (length(selected_color.rgb) > 0.01 && is_border > 0.01) {
	if (length(selected_color.rgb) > 0.01) {
		vec2 ps = 3.0 / vec2(texture_width, texture_height);
		float hl_y = 2.0 * normalized_offset;
		bool territory_edge = false;
		bool province_edge = false;
		bool is_province_hl = selected_color.r < 0.9;

		vec3 nl; vec3 ns;

		nl = texture(lookup_image, UV + vec2(ps.x, 0.0)).rgb;
		ns = texture(color_map_image, vec2(nl.r, nl.g * y_scale) + vec2(0.0, hl_y)).rgb;
		if (length(ns) < 0.01) territory_edge = true;
		if (is_province_hl && distance(ns, selected_color.rgb) > 0.01) province_edge = true;

		nl = texture(lookup_image, UV - vec2(ps.x, 0.0)).rgb;
		ns = texture(color_map_image, vec2(nl.r, nl.g * y_scale) + vec2(0.0, hl_y)).rgb;
		if (length(ns) < 0.01) territory_edge = true;
		if (is_province_hl && distance(ns, selected_color.rgb) > 0.01) province_edge = true;

		nl = texture(lookup_image, UV + vec2(0.0, ps.y)).rgb;
		ns = texture(color_map_image, vec2(nl.r, nl.g * y_scale) + vec2(0.0, hl_y)).rgb;
		if (length(ns) < 0.01) territory_edge = true;
		if (is_province_hl && distance(ns, selected_color.rgb) > 0.01) province_edge = true;

		nl = texture(lookup_image, UV - vec2(0.0, ps.y)).rgb;
		ns = texture(color_map_image, vec2(nl.r, nl.g * y_scale) + vec2(0.0, hl_y)).rgb;
		if (length(ns) < 0.01) territory_edge = true;
		if (is_province_hl && distance(ns, selected_color.rgb) > 0.01) province_edge = true;

		if (province_edge) {
			final_color = selected_color;
		} else if (territory_edge) {
			final_color = vec4(1.0);
		}
	}

	COLOR = final_color;
}
