shader_type canvas_item;

uniform sampler2D lookup_image: source_color, filter_nearest;
uniform sampler2D color_map_image: source_color, filter_nearest;

void fragment() {
	// Variables
	// Must be syncronized with map.gd (256 / 3 = 85)
	float normalized_offset = 85.0 / float(textureSize(color_map_image,0).y);
	float checkers_width = 10.0;
	float texture_width = float(textureSize(lookup_image,0).x);
	float texture_height = float(textureSize(lookup_image,0).y);
	
	// Calculate pixel position instead of using UV directly to avoid precision issues
	vec2 pixel_pos = floor(UV * vec2(texture_width, texture_height));
	int checkers_pattern = int(mod(floor(pixel_pos.x / checkers_width) + floor(pixel_pos.y / checkers_width), 2.0));

	// Textures
	vec3 lookup_texture = texture(lookup_image, UV).rgb;
	vec4 map_mode_primary = texture(color_map_image, vec2(lookup_texture.r, lookup_texture.g));
	vec4 map_mode_secondary = texture(color_map_image, vec2(lookup_texture.r, lookup_texture.g + normalized_offset));
	vec4 selected_color = texture(color_map_image, vec2(lookup_texture.r, lookup_texture.g + 2.0*normalized_offset));

	// Apply checkerboard pattern between primary and secondary
	vec4 final_color;
	bool use_secondary = false;
	
	if (checkers_pattern == 0) {
		final_color = map_mode_primary;
	} else {
		final_color = map_mode_secondary;
		use_secondary = true;
	}
	
	// Override with selection if present and flag to skip AA
	if (selected_color.rgb != vec3(0.0)) {
		final_color = selected_color;
		final_color.a = 0.0; // Skip AA for selections
	} else if (use_secondary) {
		final_color.a = 0.0; // Skip AA for secondar color
	} else {
		final_color.a = 1.0; // Apply AA for primary color only
	}

	COLOR = final_color;
}
