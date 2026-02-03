extends Resource
class_name BaseImporter

func read_lines(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		return []
	return file.get_as_text().split("\n", false)

func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		return {}
	return JSON.parse_string(file.get_as_text().strip_edges())
