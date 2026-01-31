shader_type canvas_item;

uniform sampler2D lookup_image: source_color, filter_nearest;
uniform sampler2D owner_layer_image: source_color, filter_nearest;
uniform sampler2D controller_layer_image: source_color, filter_nearest;
uniform sampler2D selected_layer_image: source_color, filter_nearest;

void fragment() {
	// Variables
	// Must be syncronized with map.gd (256 / 3 = 85)
	float checkers_width = 10.0;
	float texture_width = float(textureSize(lookup_image,0).x);
	float texture_height = float(textureSize(lookup_image,0).y);
	
	// Textures
	vec3 lookup_texture = texture(lookup_image, UV).rgb;
	vec2 lookup_position = vec2(lookup_texture.r, lookup_texture.g);

	vec4 owner_layer = texture(owner_layer_image, lookup_position);
	vec4 controller_layer = texture(controller_layer_image, lookup_position);
	vec4 selected_layer = texture(selected_layer_image, lookup_position);

	// Apply checkerboard pattern between primary and secondary
	vec4 final_color;
	
	if (selected_layer.rgb != vec3(0.0)) {
		final_color = selected_layer;
		final_color.a = 0.0; // Disable Anti-Aliasing(in map3d.gdshader)
	} else {
		// Calculate pixel position instead of using UV directly to avoid precision issues
		vec2 pixel_pos = floor(UV * vec2(texture_width, texture_height));
		float coord_sum = floor(pixel_pos.x / checkers_width) + floor(pixel_pos.y / checkers_width);
		int checkers_pattern = int(mod(coord_sum, 2.0));
		if (checkers_pattern == 0) {
			final_color = owner_layer;
		} else {
			final_color = controller_layer;
		}
		if (controller_layer.a > 0.0) {
			final_color.a = 0.0; // Disable Anti-Aliasing(in map3d.gdshader)
		}
	}
	
	COLOR = final_color;
}
