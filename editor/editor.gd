extends Node3D

var db: Database = Database.new()
var selected_province: Province

func _ready() -> void:
	DataImporter.new(db)
	$Map.create_map_modes(db)
	$ProvinceEditor.database = db
	$ProvinceEditor.populate_buttons()


func _on_controller_province_selected(mouse_pos) -> void:
	var selected_province_color: Color = $Map.get_pixel_color(mouse_pos)
	selected_province = db.color_to_province[selected_province_color]
	$Map.highlight_province(selected_province)
	$ProvinceEditor.update_labels(selected_province)


func _on_province_editor_change_owner(owner) -> void:
	selected_province.province_owner = owner
	$Map.update_map_modes(selected_province, selected_province.province_owner, 0)
	$Map.update_map()


func _on_province_editor_change_controller(controller) -> void:
	selected_province.province_controller = controller
	$Map.update_map_modes(selected_province, selected_province.province_controller, 150)
	$Map.update_map()


func _on_province_editor_change_owner_territory(owner) -> void:
	for province: Province in selected_province.territory.provinces:
		province.province_owner = owner
		$Map.update_map_modes(province, owner, 0)
	$Map.update_map()
	
	


func _on_province_editor_change_type(index) -> void:
	selected_province.type = index


func _on_province_editor_change_controller_territory(controller) -> void:
	for province: Province in selected_province.territory.provinces:
		province.province_controller = controller
		$Map.update_map_modes(province, controller, 150)
	$Map.update_map()
