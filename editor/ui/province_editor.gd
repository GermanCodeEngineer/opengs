extends CanvasLayer

@onready var province_id = $PanelContainer/GridContainer/LabelProvinceID
@onready var province_color = $PanelContainer/GridContainer/ColorPickerProvinceColor
@onready var province_type = $PanelContainer/GridContainer/OBProvinceType
@onready var province_owner = $PanelContainer/GridContainer/LabelOwner
@onready var province_controller = $PanelContainer/GridContainer/LabelController
@onready var province_territory = $PanelContainer/GridContainer/LabelTerritory
@onready var province_center = $PanelContainer/GridContainer/LabelPosition

signal connect_to_database

var database: Database
var selected_province: Province 



func _ready() -> void:
	connect_to_database.emit()
	populate_type_button()
	

func update_labels(province: Province):
	selected_province = province
	province_id.text  = str(province.id)
	province_color.color = province.color
	province_type.select(province.type)

	province_center.text = str(province.center)
	province_territory.text = str(province.territory.id)
	if province.type == Province.Type.LAND:
		province_owner.text = province.province_owner.tag
		province_controller.text = province.province_controller.tag	
	else:
		province_owner.text = ""
		province_controller.text = ""


func _on_button_gen_prv_button_up() -> void:
	var exporter = ProvinceExporter.new()
	exporter.write_definition(database)
	exporter.write_history(database)


func _on_ob_province_type_item_selected(index: int) -> void:
	selected_province.type = index

func populate_type_button() -> void:
	for type in Province.Type:
		province_type.add_item(type)
