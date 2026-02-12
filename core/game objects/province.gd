extends Resource

class_name Province

enum Type { LAND, LAKE, OCEAN }

var id: String
var color: Color
var type: Type
var center: Vector2
var territory: Territory:
	set(value):
		if territory != null:
			territory.provinces.erase(self)
		territory = value
		territory.provinces.append(self)
		
var province_owner: Country:
	set(value):
		if province_owner != null:
			province_owner.owned_provinces.erase(self)
		province_owner = value
		province_owner.owned_provinces.append(self)
var province_controller: Country

func _init(province_id: String, province_color: Color, province_type: Type, province_center: Vector2) -> void:
	self.id = province_id
	self.color = province_color
	self.center = province_center
	self.type = province_type
