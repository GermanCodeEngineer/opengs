extends StaticBody3D

@onready var province_color_to_lookup : Dictionary
@onready var map_material_2d = load("res://map/shaders/map2D.tres")
@onready var color_layer_political_owner:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var color_layer_political_controller:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var color_layer_ideology_owner:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var color_layer_ideology_controller:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var color_layer_states:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var color_layer_provinces:Image = Image.create(256,256,false,Image.FORMAT_RGB8)

@onready var color_layer_selected:Image = Image.create(256,256,false,Image.FORMAT_RGB8)
@onready var empty_image:Image = Image.create(256,256,false,Image.FORMAT_RGBA8)

var current_owner_layer:Image
var current_controller_layer:Image

var previously_selected_provinces :PackedColorArray

enum MapMode {POLITICAL, IDEOLOGY, STATES, PROVINCES}

func _ready() -> void:
	create_lookup_texture()
	create_color_map()
	set_map_mode_political()
	create_country_labels()
	
func create_lookup_texture() -> void:
	var province_image : Image = get_parent().province_map.get_image()
	var lookup_image: Image = province_image.duplicate()
	var color_map_r : int = 0
	var color_map_g : int = 0
	
	for x in range(lookup_image.get_width()):
		for y in range(lookup_image.get_height()):
			var province_color : Color = province_image.get_pixel(x,y)
			if not province_color_to_lookup.has(province_color):
				province_color_to_lookup[province_color] = Color(color_map_r/255.0, color_map_g/255.0, 0.0)
				color_map_r += 1
				if color_map_r == 256:
					color_map_r = 0
					color_map_g += 1
					if color_map_g == 256:
						push_error("Too many provinces! Max is 256*256 = %d" % (256*256))
			lookup_image.set_pixel(x,y,province_color_to_lookup[province_color])
	var lookup_texture = ImageTexture.create_from_image(lookup_image)
	map_material_2d.set_shader_parameter("lookup_image", lookup_texture)
	
func create_color_map() -> void:
	for province_color :Color in province_color_to_lookup:
		var lookup = province_color_to_lookup[province_color]
		var x = lookup.r * 255
		var y = lookup.g * 255
		var province:Province = get_parent().get_node("Provinces").color_to_province.get(province_color)
		if province.type == "land":
			var owner_color :Color = province.province_owner.color
			var controller_color :Color = province.province_controller.color
			color_layer_political_owner.set_pixel(x,y,owner_color)
			color_layer_political_controller.set_pixel(x,y,Color("222")) # controller_color
			
			var owner_ideology_color :Color = province.province_owner.ideology_color
			var controller_ideology_color :Color = province.province_controller.ideology_color
			color_layer_ideology_owner.set_pixel(x,y,owner_ideology_color)
			color_layer_ideology_controller.set_pixel(x,y,controller_ideology_color)
			
			var first_sibling :Province = province.get_parent().get_children()[0]
			color_layer_states.set_pixel(x, y, first_sibling.color)
			color_layer_provinces.set_pixel(x, y, province.color)
		else:
			# Ocean/sea provinces - set both channels to black to avoid checkerboard artifacts
			color_layer_political_owner.set_pixel(x, y, Color.BLACK)
			color_layer_political_controller.set_pixel(x, y, Color.BLACK)
			color_layer_ideology_owner.set_pixel(x, y, Color.BLACK)
			color_layer_ideology_controller.set_pixel(x, y, Color.BLACK)
			color_layer_states.set_pixel(x, y, Color.BLACK)
			color_layer_provinces.set_pixel(x, y, Color.BLACK)

func update_map_selection(input_color:Color, output_color:Color) -> void:
	var lookup = province_color_to_lookup.get(input_color,null)
	if lookup:
		var x = lookup.r * 255
		var y = lookup.g * 255
		color_layer_selected.set_pixel(x,y,output_color)
	
	
func update_map_shader() -> void:
	var owner_layer_texture = ImageTexture.create_from_image(current_owner_layer)
	var controller_layer_texture = ImageTexture.create_from_image(current_controller_layer)
	var selected_layer_texture = ImageTexture.create_from_image(color_layer_selected)
	map_material_2d.set_shader_parameter("owner_layer_image", owner_layer_texture)
	map_material_2d.set_shader_parameter("controller_layer_image", controller_layer_texture)
	map_material_2d.set_shader_parameter("selected_layer_image", selected_layer_texture)

func set_map_mode_political() -> void:
	current_owner_layer = color_layer_political_owner
	current_controller_layer = color_layer_political_controller
	update_map_shader()
	
func set_map_mode_ideology() -> void:
	current_owner_layer = color_layer_ideology_owner
	current_controller_layer = color_layer_ideology_controller
	update_map_shader()

func set_map_mode_states() -> void:
	current_owner_layer = color_layer_states
	current_controller_layer = empty_image
	update_map_shader()

func set_map_mode_provinces() -> void:
	current_owner_layer = color_layer_provinces
	current_controller_layer = empty_image
	update_map_shader()

func highlight_province(selected_province) -> void:
	deselect_provinces()
	if selected_province.type == "land":
		for province in selected_province.get_parent().get_children():
			update_map_selection(province.color, Color(0.6, 0.6, 0.6))
			previously_selected_provinces.append(province.color)
			
	update_map_selection(selected_province.color, Color("Green"))
	update_map_shader()
	previously_selected_provinces.append(selected_province.color)
	
func deselect_provinces() -> void:
	for color in previously_selected_provinces:
		update_map_selection(color, Color("BLACK"))
	previously_selected_provinces.clear()


func _on_map_modes_map_mode_selected(mode: Variant) -> void:
	match mode:
		MapMode.POLITICAL:
			set_map_mode_political()
		MapMode.IDEOLOGY:
			set_map_mode_ideology()
		MapMode.STATES:
			set_map_mode_states()
		MapMode.PROVINCES:
			set_map_mode_provinces()

func create_country_labels() -> void:
	var country_label_template: PackedScene = load("res://map/country_label_template.tscn")
	for country: Country in Globals.tag_to_country.values():
		var country_label = country_label_template.instantiate()
		country_label.initial_data(country)
		$MeshInstance3D/SubViewport2/CountryLabels.add_child(country_label)
		country_label.update_data(country)
