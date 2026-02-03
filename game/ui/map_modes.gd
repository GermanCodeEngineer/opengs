extends CanvasLayer
signal map_mode_selected(mode)

func _on_button_political_button_up() -> void:
	map_mode_selected.emit(MapMode.Type.POLITICAL)

func _on_button_ideology_button_up() -> void:
	map_mode_selected.emit(MapMode.Type.IDEOLOGY)
