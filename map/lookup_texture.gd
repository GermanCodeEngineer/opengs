extends ImageTexture
class_name LookupTexture

var province_color_to_lookup: Dictionary[Color, Color]

func _init(province_image: Image) -> void:
	var lookup_image: Image = _create_lut(province_image)
	self.set_image(lookup_image)


func _create_lut(province_image: Image) -> Image:
	var _lookup_image: Image = province_image.duplicate()
	var color_map_r: int = 0
	var color_map_g: int = 0
	for x in range(_lookup_image.get_width()):
		for y in range(_lookup_image.get_height()):
			var province_color : Color = province_image.get_pixel(x,y)
			if not province_color_to_lookup.has(province_color):
				province_color_to_lookup[province_color] = Color(color_map_r/255.0, color_map_g/255.0, 0.0)
				color_map_r += 1
				if color_map_r == 256:
					color_map_r = 0
					color_map_g += 1
			_lookup_image.set_pixel(x,y,province_color_to_lookup[province_color])
	return _lookup_image
