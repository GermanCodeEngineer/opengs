shader_type spatial;

// Images
uniform sampler2D terrain_image: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D subview_image: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normalmap_image: hint_normal, repeat_enable;

// Parameters
uniform float threshold = 0.1;
uniform float aa_scale = 17.6;
const int ML = 0;

// Bilinear-weighted fetch: averages the four surrounding texels weighted by proximity
// (closer texel = higher weight, farther texel = lower weight)
vec4 bfetch(vec2 pos) {
	vec2 f = fract(pos);
	ivec2 i = ivec2(floor(pos));
	vec4 s00 = texelFetch(subview_image, i, ML);
	vec4 s10 = texelFetch(subview_image, i + ivec2(1, 0), ML);
	vec4 s01 = texelFetch(subview_image, i + ivec2(0, 1), ML);
	vec4 s11 = texelFetch(subview_image, i + ivec2(1, 1), ML);
	return mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
	//return texelFetch(subview_image, ivec2(floor(pos)), ML);
	//return mix(
	//	texelFetch(subview_image, ivec2(floor(pos)), ML),
	//	texelFetch(subview_image, ivec2(ceil(pos)), ML),
	//	fract(normalize(pos).x)
	//);
}

// Diagonal line blending logic
bool diag(inout vec4 sum, vec2 ip, vec2 p1, vec2 p2, float thickness) {
	vec4 v1 = bfetch(ip + p1);
	vec4 v2 = bfetch(ip + p2);

	if (length(v1 - v2) < threshold) {
		vec2 dir = normalize(vec2((p2 - p1).y, -(p2 - p1).x));
		vec2 lp = ip - (floor(ip + p1) + vec2(0.5));
		float l = clamp((thickness - dot(lp, dir)) * aa_scale, 0.0, 1.0);
		sum = mix(sum, v1, l);
		return true;
	}
	return false;
}

void fragment() {
	// Textures

	vec3 subview_texture = texture(subview_image,UV).rgb;
	vec3 terrain_texture = texture(terrain_image,UV).rgb;
	vec3 normalmap_texture = texture(normalmap_image,UV).rgb;

	// Apply smoothing
	vec2 tex_size = vec2(textureSize(subview_image, 0));
	vec2 ip = UV * tex_size;
	vec4 s = bfetch(ip);
	if (false) {
		if (diag(s, ip, vec2(-1, 0), vec2(0, 1), 0.38*7.86)) {
			diag(s, ip, vec2(-1, 0), vec2(1, 1), 0.25*5.91);
			diag(s, ip, vec2(-1, -1), vec2(0, 1), 0.25*4.43);
		}
		if (diag(s, ip, vec2(0, 1), vec2(1, 0), 0.38*3.33)) {
			diag(s, ip, vec2(0, 1), vec2(1, -1), 0.25*2.49);
			diag(s, ip, vec2(-1, 1), vec2(1, 0), 0.25*1.87);
		}
		if (diag(s, ip, vec2(1, 0), vec2(0, -1), 0.38*1.40)) {
			diag(s, ip, vec2(1, 0), vec2(-1, -1), 0.25*1.05);
			diag(s, ip, vec2(1, 1), vec2(0, -1), 0.25*0.79);
		}
		if (diag(s, ip, vec2(0, -1), vec2(-1, 0), 0.38*0.59)) {
			diag(s, ip, vec2(0, -1), vec2(-1, 1), 0.25*0.44);
			diag(s, ip, vec2(1, -1), vec2(-1, 0), 0.25*0.33);
		}
	}


	ALBEDO = s.rgb; //final_color;//s.rgb; //mix(s.rgb, terrain_texture, 0.4);
	NORMAL_MAP = normalmap_texture;
}
