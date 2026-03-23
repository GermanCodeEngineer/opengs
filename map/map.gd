extends StaticBody3D

@onready var sub_viewport: SubViewport = $MeshInstance3D/SubViewport
@onready var map_sprite: Sprite2D = $MeshInstance3D/SubViewport/Sprite2D
@onready var map_material_2d: ShaderMaterial = $MeshInstance3D/SubViewport/Sprite2D.material

var country_label_scene: PackedScene = preload("res://map/country_label.tscn")


var tex_gen: MapTextureGenerator
var mm_political: MapMode
var mm_ideology: MapMode
var mm_province: MapMode
var mm_territory: MapMode
var current_map_mode: MapMode
var current_highlight: MapHighlight

var all_map_modes: Array[MapMode]


func _ready() -> void:
	await create_map_textures()

func _process(_delta: float) -> void:
	var image_name = null
	if Input.is_action_just_pressed("set_province_image_full"):
		image_name = "provinces_9821x6347.png"
		print("Setting province image to full resolution.")
	elif Input.is_action_just_pressed("set_province_image_half"):
		image_name = "provinces_4910x3174.png"
		print("Setting province image to half resolution.")
	elif Input.is_action_just_pressed("set_province_image_quarter"):
		image_name = "provinces_2455x1587.png"
		print("Setting province image to quarter resolution.")

	
	if image_name != null:
		var img = Image.load_from_file("res://map/map_data/scaled_provinces/" + image_name)
		var tex = ImageTexture.create_from_image(img)
		set_province_image(tex)


func _wait_for_province_image(max_frames: int = 120) -> Image:
	for _i in max_frames:
		var tex: Texture2D = map_sprite.texture
		if tex != null:
			var image := tex.get_image()
			if image != null:
				return image
		await get_tree().process_frame
	push_warning("Map texture was not ready after waiting %d frames." % max_frames)
	return null


func get_pixel_lookup_color(rel_mouse_pos: Vector2) -> Color:
	var mouse_pos = rel_mouse_pos * tex_gen.lookup_texture.get_size()
	return tex_gen.lookup_texture.get_image().get_pixel(mouse_pos.x, mouse_pos.y)

func create_map_textures() -> void:
	var province_image := await _wait_for_province_image()
	if province_image == null:
		push_error("Cannot create map textures: province image is not available.")
		return

	tex_gen = MapTextureGenerator.new(province_image)
	var lookup_img = tex_gen.lookup_texture.get_image()
	print("[DEBUG] Created lookup_texture size: %dx%d" % [lookup_img.get_width(), lookup_img.get_height()])
	map_material_2d.set_shader_parameter("lookup_image", tex_gen.lookup_texture)
	map_material_2d.set_shader_parameter("province_border_image", tex_gen.border_texture)
	tex_gen.lookup_texture.get_image().save_png("res://map/map_data/lut_preview.png") # remove in PROD, just for visuals in editor
	tex_gen.border_texture.get_image().save_png("res://map/map_data/bt_preview.png") # remove in PROD, just for visuals in editor

	# Set Sprite2D texture to lookup_texture
	# It has the same size => less memory usage => the shader overrides the displayed content anyway
	set_province_image(tex_gen.lookup_texture)

func create_map_modes(db: Database) -> void:
	mm_political = MapMode.new(tex_gen.province_color_to_lookup, db.color_to_province, MapMode.Type.POLITICAL)
	mm_ideology = MapMode.new(tex_gen.province_color_to_lookup, db.color_to_province, MapMode.Type.IDEOLOGY)
	mm_province = MapMode.new(tex_gen.province_color_to_lookup, db.color_to_province, MapMode.Type.PROVINCE)
	mm_territory = MapMode.new(tex_gen.province_color_to_lookup, db.color_to_province, MapMode.Type.TERRITORY)
	all_map_modes = [mm_political, mm_ideology, mm_province, mm_territory]
	set_map_mode(MapMode.Type.POLITICAL)
	mm_political.get_image().save_png("res://map/map_data/cmap_preview.png")
	
func create_country_labels(db: Database) -> void:
	for country: Country in db.tag_to_country.values():
		var country_label: CountryLabel = country_label_scene.instantiate()
		country_label.initial_data(country)
		%CountryLabels.add_child(country_label)
		country_label.update_data(country)
		
func update_country_label(country: Country) -> void:
	if country != null:
		var label: CountryLabel = %CountryLabels.get_node(country.tag)
		label.update_data(country)
	

# Sets the Sprite2D texture to the given image and scales it to fill the SubViewport
func set_province_image(image: Texture2D) -> void:
	map_sprite.texture = image
	var sprite_size = image.get_size()
	var viewport_size = sub_viewport.size
	map_sprite.scale = Vector2(viewport_size.x / sprite_size.x, viewport_size.y / sprite_size.y)
	print("Set province image with size: %dx%d, scaled to viewport size: %dx%d" % [sprite_size.x, sprite_size.y, viewport_size.x, viewport_size.y])


func update_map() -> void:
	map_material_2d.set_shader_parameter("color_map_image", current_map_mode)


func set_map_mode(map_mode: MapMode.Type) -> void:
	if current_highlight != null:
		current_map_mode = current_highlight.remove_highlights(current_map_mode)
	match map_mode:
		MapMode.Type.POLITICAL:
			current_map_mode = mm_political
		MapMode.Type.IDEOLOGY:
			current_map_mode = mm_ideology
		MapMode.Type.PROVINCE:
			current_map_mode = mm_province
		MapMode.Type.TERRITORY:
			current_map_mode = mm_territory
	if current_highlight != null:
		current_map_mode = current_highlight.apply_highlights(current_map_mode)
	update_map()
	
func update_map_modes(province: Province, country: Country, offset: int) -> void:
	for mm in all_map_modes:
		mm.update_color_map(province.color, country.map_color, offset)



func highlight_province(province: Province):
	if current_highlight != null:
		current_map_mode = current_highlight.remove_highlights(current_map_mode)
	current_highlight = MapHighlight.new(province)
	current_map_mode = current_highlight.apply_highlights(current_map_mode)
	update_map()
	
