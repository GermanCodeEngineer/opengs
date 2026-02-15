extends ImageTexture
class_name ProvinceBorderTexture

const BORDER_COLOR = Color("BLACK")
const BG_COLOR = Color("WHITE")

func _init(province_image: Image) -> void:
	var province_border_image: Image = _create_bt(province_image)
	self.set_image(province_border_image)


func _create_bt(province_image: Image) -> Image:
	var border_image: Image = province_image.duplicate()

	var neighbors = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
	]

	for x in range(border_image.get_width()):
		for y in range(border_image.get_height()):
			var current_color = province_image.get_pixel(x, y)
			var is_border = false

			for offset in neighbors:
				var nx = x + offset.x
				var ny = y + offset.y

				if nx >= 0 and nx < border_image.get_width() and ny >= 0 and ny < border_image.get_height():
					var neighbor_color = province_image.get_pixel(nx, ny)
					if neighbor_color != current_color:
						is_border = true
						break

			if is_border:
				border_image.set_pixel(x, y, BORDER_COLOR)
			else:
				border_image.set_pixel(x, y, BG_COLOR)

	return border_image
