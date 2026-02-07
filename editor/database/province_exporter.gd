extends Resource
class_name ProvinceExporter


func write_definition(db: Database) -> void:
	var path = "res://data/definitions/provinces.txt"
	var file = FileAccess.open(path, FileAccess.WRITE)
	for province: Province in db.id_to_province.values():
		var data = ProvinceConverter.new(province)
		file.store_line(";".join(data.definition_data.map(func(v): return str(v))))
	file.close()


func write_history(db: Database) -> void:
	for province: Province in db.id_to_province.values():
		var path: String
		path = "res://data/history/provinces/" + province.id + ".json"
		var data = ProvinceConverter.new(province)
		var json_string = JSON.stringify(data.history_data)
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(json_string)
		file.close()
