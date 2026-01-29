extends Node

signal  reparent_provinces

func  _ready() -> void:
	generate_states()
	assign_owners()
	
func generate_states() -> void:
	print("STARTING TO GENERATE STATES")
	var state_folder = DirAccess.open("res://map/map_data/States/")
	state_folder.list_dir_begin()
	var file_name = state_folder.get_next()
	while file_name != "":
		var state_file = FileAccess.open("res://map/map_data/States/" + file_name,FileAccess.READ)
		var file_content = state_file.get_as_text().strip_edges()
		state_file.close()
		#id
		var from = file_content.find("id=")+3
		var to = file_content.find("name=")-from
		var id = int(file_content.substr(from,to))
		#name
		from = file_content.find("name=")+5
		to = file_content.find("provinces=")-from
		var state_name = str(file_content.substr(from,to)).replace('"',"")
		#provinces
		from = file_content.find("provinces=")+11
		to = file_content.find("}")-from
		var provinces = file_content.substr(from,to).strip_edges().split(" ")
		
		#Create State
		var state:State = State.new()
		state.name = str(id)
		state.id = id
		state.state_name = state_name
		state.provinces = provinces
		add_child(state)
		reparent_provinces.emit(state)
		
		#
		file_name = state_folder.get_next()
	state_folder.list_dir_end()
	print("Finished generating states!")


# Dictionary mapping country codes to their state IDs
var state_ownership := {
	"FRA": [925, 931, 936, 470, 926, 386],
	"DEU": [322, 332],
	"GBR": [261, 318, 265, 272, 307, 294, 243, 309],
	"PRT": [475],
	"ITA": [483, 500, 429],
	"CZE": [387, 404],
	"POL": [325],
	"AUT": [409, 452],
	"NOR": [133, 64, 240, 195, 137, 122, 121, 74, 255, 253, 228, 213, 183, 104, 86, 95, 150, 131, 72],
	"HUN": [416],
	"SWE": [879, 117, 279, 277, 289, 262],
	"ESP": [465, 963, 960, 946, 489, 490, 492],
	"BGR": [464],
	"ROM": [421],
	"GRC": [499, 482, 493, 506, 517],
	"DNK": [321, 304, 286, 310, 314, 323],
	"CHE": [425],
	"BEN": [379, 353, 377],
	"SER": [436, 473, 474, 439, 467, 459],
	"IRL": [331],
	"ISL": [157],
	"FIN": [87, 247, 224, 196, 193],
	"USR": [296, 274, 254, 875, 302, 366, 417, 68, 908, 437, 440, 258, 263, 191, 211, 441, 438],
}

func assign_owners() -> void:
	for country_code in state_ownership:
		for state_id in state_ownership[country_code]:
			var state_node = get_node(str(state_id))
			if state_node:
				state_node.set_state_owner(country_code)
				state_node.set_state_controller(country_code)
	
