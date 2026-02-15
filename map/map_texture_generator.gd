class_name MapTextureGenerator

var lookup_texture: ImageTexture
var border_texture: ImageTexture
var province_color_to_lookup: Dictionary[Color, Color]


func _init(province_image: Image) -> void:
	_generate(province_image)


func _generate(province_image: Image) -> void:
	var width: int = province_image.get_width()
	var height: int = province_image.get_height()
	var src_data: PackedByteArray = province_image.get_data()
	var bpp: int = src_data.size() / (width * height)
	var src_stride: int = width * bpp

	var out_size: int = width * height * 3
	var out_stride: int = width * 3

	var lut_data: PackedByteArray = PackedByteArray()
	lut_data.resize(out_size)
	var border_data: PackedByteArray = PackedByteArray()
	border_data.resize(out_size)

	var color_key_to_lookup: Dictionary[int, Vector2i] = {}
	var color_map_r: int = 0
	var color_map_g: int = 0

	for y in range(height):
		for x in range(width):
			var src_idx: int = y * src_stride + x * bpp
			var out_idx: int = y * out_stride + x * 3
			var r: int = src_data[src_idx]
			var g: int = src_data[src_idx + 1]
			var b: int = src_data[src_idx + 2]
			var key: int = (r << 16) | (g << 8) | b

			# --- Lookup texture ---
			if not color_key_to_lookup.has(key):
				color_key_to_lookup[key] = Vector2i(color_map_r, color_map_g)
				province_color_to_lookup[Color(r / 255.0, g / 255.0, b / 255.0)] = Color(color_map_r / 255.0, color_map_g / 255.0, 0.0)
				color_map_r += 1
				if color_map_r == 256:
					color_map_r = 0
					color_map_g += 1

			var lookup: Vector2i = color_key_to_lookup[key]
			lut_data[out_idx] = lookup.x
			lut_data[out_idx + 1] = lookup.y
			lut_data[out_idx + 2] = 0

			# --- Border texture ---
			var is_border: bool = false
			if x > 0:
				var ni: int = src_idx - bpp
				if src_data[ni] != r or src_data[ni + 1] != g or src_data[ni + 2] != b:
					is_border = true
			if not is_border and x < width - 1:
				var ni: int = src_idx + bpp
				if src_data[ni] != r or src_data[ni + 1] != g or src_data[ni + 2] != b:
					is_border = true
			if not is_border and y > 0:
				var ni: int = src_idx - src_stride
				if src_data[ni] != r or src_data[ni + 1] != g or src_data[ni + 2] != b:
					is_border = true
			if not is_border and y < height - 1:
				var ni: int = src_idx + src_stride
				if src_data[ni] != r or src_data[ni + 1] != g or src_data[ni + 2] != b:
					is_border = true

			if is_border:
				border_data[out_idx] = 0
				border_data[out_idx + 1] = 0
				border_data[out_idx + 2] = 0
			else:
				border_data[out_idx] = 255
				border_data[out_idx + 1] = 255
				border_data[out_idx + 2] = 255

	var lut_image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, lut_data)
	lookup_texture = ImageTexture.create_from_image(lut_image)

	var border_image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, border_data)
	border_texture = ImageTexture.create_from_image(border_image)
