extends Node3D

var db: Database = Database.new()
var selected_province: Province

func _ready() -> void:
	DataImporter.new(db)
	$Map.create_map_modes(db)
	$ProvinceEditor.database = db
	$ProvinceEditor.populate_buttons()


func _on_controller_province_selected(mouse_pos: Vector2) -> void:
	var selected_province_color: Color = $Map.get_pixel_color(mouse_pos)
	selected_province = db.color_to_province[selected_province_color]
	$Map.highlight_province(selected_province)
	$ProvinceEditor.update_labels(selected_province)


func _on_province_editor_change_owner(province_owner: Country) -> void:
	selected_province.province_owner = province_owner
	$Map.update_map_modes(selected_province, selected_province.province_owner, MapMode.PRIMARY_OFFSET)
	$Map.update_map()


func _on_province_editor_change_controller(controller: Country) -> void:
	selected_province.province_controller = controller
	$Map.update_map_modes(selected_province, selected_province.province_controller, MapMode.SECONDARY_OFFSET)
	$Map.update_map()


func _on_province_editor_change_owner_territory(province_owner: Country) -> void:
	for province: Province in selected_province.territory.provinces:
		province.province_owner = province_owner
		$Map.update_map_modes(province, province_owner, MapMode.PRIMARY_OFFSET)
	$Map.update_map()
	
	


func _on_province_editor_change_type(index: int) -> void:
	selected_province.type = index


func _on_province_editor_change_controller_territory(controller: Country) -> void:
	for province: Province in selected_province.territory.provinces:
		province.province_controller = controller
		$Map.update_map_modes(province, controller, MapMode.SECONDARY_OFFSET)
	$Map.update_map()


func _on_province_editor_export_requested() -> void:
	var exporter = ProvinceExporter.new()
	exporter.write_definition(db)
	exporter.write_history(db)
