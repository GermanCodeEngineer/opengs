extends Node3D

var db: Database = Database.new()
var selected_province: Province

func _ready() -> void:
	DataImporter.new(db)
	$Map.create_map_modes(db)


func _on_controller_province_selected(mouse_pos) -> void:
	var selected_province_color: Color = $Map.get_pixel_color(mouse_pos)
	selected_province = db.color_to_province[selected_province_color]
	$Map.highlight_province(selected_province)
	$ProvinceEditor.update_labels(selected_province)

func _on_province_editor_connect_to_database() -> void:
	$ProvinceEditor.database = db
