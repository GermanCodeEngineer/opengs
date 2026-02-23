
class_name MapTextureGenerator

var lookup_texture: ImageTexture
var border_texture: ImageTexture
var province_color_to_lookup: Dictionary[Color, Color]
var cache_id

func _init(province_image: Image) -> void:
	var hash_img_data = province_image.get_data()
	self.cache_id = Marshalls.raw_to_base64(hash_img_data).md5_text() 
	#check the existence of the map cache
	if FileAccess.file_exists("user://map_cache/{id}/lookup_texture.png".format({"id":self.cache_id})) and FileAccess.file_exists("user://map_cache/{id}/border_texture.png".format({"id":self.cache_id})) and  FileAccess.file_exists("user:///map_cache/{id}/province_color_to_lookup.data".format({"id":self.cache_id})):
		print("cache load map")	
		var lut_image: Image = Image.load_from_file("user://map_cache/{id}/lookup_texture.png".format({"id":self.cache_id}))
		lookup_texture = ImageTexture.create_from_image(lut_image)
		var border_image: Image = Image.load_from_file("user://map_cache/{id}/border_texture.png".format({"id":self.cache_id}))
		border_texture = ImageTexture.create_from_image(border_image)
		var province_color_to_lookup_file = FileAccess.open("user://map_cache/{id}/province_color_to_lookup.data".format({"id":self.cache_id}), FileAccess.READ)
		province_color_to_lookup = str_to_var(province_color_to_lookup_file.get_as_text())
		province_color_to_lookup_file.close()
		print("cache load map end")	
	else:
		print("generation map")	
		_generate(province_image)
		print("generation map end")	

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
	var folder_path = "user://map_cache/{id}".format({"id": self.cache_id})
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	var lut_image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, lut_data)
	lookup_texture = ImageTexture.create_from_image(lut_image)
	lookup_texture.get_image().save_png("user://map_cache/{id}/lookup_texture.png".format({"id":self.cache_id})) #сache "Baked" image of map for fast loading
	var border_image: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGB8, border_data)
	border_texture = ImageTexture.create_from_image(border_image)
	border_texture.get_image().save_png("user://map_cache/{id}/border_texture.png".format({"id":self.cache_id})) #сache "Baked" image of map for fast loading
	var province_color_to_lookup_file = FileAccess.open("user://map_cache/{id}/province_color_to_lookup.data".format({"id":self.cache_id}), FileAccess.WRITE)
	if province_color_to_lookup_file:
		province_color_to_lookup_file.store_string(var_to_str(province_color_to_lookup))
		province_color_to_lookup_file.close()
