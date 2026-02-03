extends Resource

class_name Territory

var id: String
var provinces: Array[Province]

func _init(territory_id) -> void:
	self.id = territory_id

func set_owner(new_owner: Country) -> void:
	for province: Province in provinces:
		province.province_owner = new_owner

func set_controller(new_controller: Country) -> void:
	for province: Province in provinces:
		province.province_controller = new_controller
