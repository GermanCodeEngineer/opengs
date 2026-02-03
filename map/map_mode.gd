extends ImageTexture
class_name MapMode

enum Type {POLITICAL, IDEOLOGY}
var _province_color_to_lookup: Dictionary[Color, Color]
var color_map: Image


func _init(province_color_to_lookup: Dictionary[Color, Color], color_to_province: Dictionary[Color, Province], type: Type) -> void:
	color_map = _create_color_map(province_color_to_lookup, color_to_province, type)
	self._province_color_to_lookup = province_color_to_lookup
	self.set_image(color_map)



func _create_color_map(province_color_to_lookup, color_to_province, type) -> Image:
	var _color_map = Image.create(256,512,false,Image.FORMAT_RGB8)
	for province_color: Color in province_color_to_lookup:
		var lookup: Color = province_color_to_lookup[province_color]
		var x = lookup.r * 255
		var y = lookup.g * 255
		var province: Province = color_to_province[province_color]
		if province.type == Province.Type.LAND:
			match type:
				Type.POLITICAL:
					_color_map.set_pixel(x, y, province.province_owner.map_color)
					_color_map.set_pixel(x, y + 150, province.province_controller.map_color)

				Type.IDEOLOGY:
					match province.province_owner.ideology:
						Country.Ideology.DEMOCRACY:
							_color_map.set_pixel(x, y, Color(0.0, 0.0, 1.0, 1.0))
						Country.Ideology.COMMUNISM:
							_color_map.set_pixel(x, y, Color(1.0, 0.0, 0.0, 1.0))
							
					match province.province_controller.ideology:
						Country.Ideology.DEMOCRACY:
							_color_map.set_pixel(x, y + 150, Color(0.0, 0.0, 1.0, 1.0))
						Country.Ideology.COMMUNISM:
							_color_map.set_pixel(x, y + 150, Color(1.0, 0.0, 0.0, 1.0))
	return _color_map

func update_color_map(input_color: Color, output_color: Color, offset: int) -> void:
	var lookup = _province_color_to_lookup.get(input_color, null)
	if lookup:
		var x = lookup.r * 255
		var y = lookup.g * 255
		color_map.set_pixel(x, y + offset, output_color)
		self.set_image(color_map)
