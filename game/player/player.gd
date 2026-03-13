extends Node3D
signal province_selected

# Imports

# Nodes
@onready var camera: Camera3D = $CameraSocket/Camera3D
@onready var camera_socket: Node3D = $CameraSocket

# Control variables # TODO: fine tune
# Camera Movement
var camera_move := ControlVariables.new(
	50.0, # acceleration_speed_factor
	0.15, # velocity_half_life
	Vector3.ZERO, # velocity
	Vector3.ZERO, # frame_acceleration
)
var camera_touchpad_move:Vector2 = Vector2.ZERO

# Camera Rotation
var camera_rotate_x := ControlVariables.new(
	1.5, # acceleration_speed_factor
	0.00, # velocity_half_life (velocity immediately reset)
	0.0, # velocity
	0.0, # frame_acceleration
	-1.60, # min_bound
	-0.20, # max_bound
)

var camera_rotate_y := ControlVariables.new(
	1.5, # acceleration_speed_factor
	0.15, # velocity_half_life
	0.0, # velocity
	0.0, # frame_acceleration
)

# Camera Zooming
var camera_zoom := ControlVariables.new(
	300.0, # acceleration_speed_factor
	0.15, # velocity_half_life
	0.0, # velocity
	0.0, # frame_acceleration
	10.0, # min_bound
	1000.0, # max_bound
)

# Camera Panning
@export_range(0,32,4) var camera_automatic_pan_margin:int = 16
@export_range(0,20,0.5) var camera_automatic_pan_speed:float = 18


# Flags
var camera_can_process:bool = true
var camera_can_move_base:bool = true
var camera_can_zoom:bool = true
var camera_can_automatic_pan:bool = false
var camera_can_rotate_base:bool = true
var camera_can_rotate_by_mouse_offfset:bool = true

# Internal Flags
var camera_is_rotating_mouse:bool = false
var mouse_last_position:Vector2 = Vector2.ZERO



func _ready() -> void:
	pass
	
func _process(delta:float) -> void:
	if !camera_can_process: return
	camera_base_move(delta)
	camera_zoom_update(delta)
	camera_automatic_pan(delta)
	camera_base_rotate(delta)
	camera_rotate_to_mouse_offsets(delta)
	_show_fps()

# Show FPS on the window
func _show_fps():
	var fps = Engine.get_frames_per_second()
	if not has_node("FPSLabel"):
		var label = Label.new()
		label.name = "FPSLabel"
		label.text = "FPS: %d" % fps
		label.set_position(Vector2(10, 10))
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.add_theme_color_override("font_color", Color(1,1,0))
		add_child(label)
	else:
		var label = get_node("FPSLabel")
		label.text = "FPS: %d" % fps


# Moves the base of camera
func camera_base_move(delta:float) -> void:
	if !camera_can_move_base: return

	# Process Inputs
	if Input.is_action_pressed("camera_forward"): camera_move.frame_acceleration -= transform.basis.z
	if Input.is_action_pressed("camera_backward"): camera_move.frame_acceleration += transform.basis.z
	if Input.is_action_pressed("camera_right"): camera_move.frame_acceleration += transform.basis.x
	if Input.is_action_pressed("camera_left"): camera_move.frame_acceleration -= transform.basis.x
	#camera_move.frame_acceleration.x += camera_touchpad_move.x 	# Temporarily disabled
	#camera_move.frame_acceleration.z += camera_touchpad_move.y     # TODO: reenable
	camera_move.frame_acceleration = camera_move.frame_acceleration.normalized()

	# Add acceleration to velocity and reset
	camera_move.velocity += camera_move.frame_acceleration * camera_move.acceleration_speed_factor
	camera_move.frame_acceleration = Vector3.ZERO
	
	# Apply velocity and dampen
	position += camera_move.velocity * delta
	camera_move.velocity *= _dampen_with_half_life(camera_move.velocity_half_life, delta)


func _unhandled_input(event: InputEvent) -> void:
	
		## Exit
	if Input.is_action_pressed("Exit"):
		get_tree().quit()
	
	# Camera Move
	if event is InputEventPanGesture:
		camera_touchpad_move = event.delta

	
	# Camera Zoom
	if event.is_action("camera_zoom_in"):
		camera_zoom.frame_acceleration -= 1
	elif  event.is_action("camera_zoom_out"):
		camera_zoom.frame_acceleration += 1
	if event is InputEventMagnifyGesture: # TODO: test
		camera_zoom.frame_acceleration += (1-event.factor)
	
	
	# Camera rotations		
	if event.is_action_pressed("camera_rotate"):
		mouse_last_position = get_viewport().get_mouse_position()
		camera_is_rotating_mouse = true
	elif event.is_action_released("camera_rotate"):
		camera_is_rotating_mouse = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot_ray()


func camera_zoom_update(delta:float) -> void:
	if !camera_can_zoom: return
	# Add acceleration to velocity and reset
	camera_zoom.velocity += camera_zoom.frame_acceleration * camera_zoom.acceleration_speed_factor
	camera_zoom.frame_acceleration = 0
	
	# Apply velocity and dampen
	camera.position.z += camera_zoom.velocity * delta
	camera.position.z = clamp(camera.position.z, camera_zoom.min_bound, camera_zoom.max_bound)
	camera_zoom.velocity *= _dampen_with_half_life(camera_zoom.velocity_half_life, delta)


# Rotate the camera socket based on mouse offset
func camera_rotate_to_mouse_offsets(delta:float) -> void:
	if !camera_can_rotate_by_mouse_offfset or !camera_is_rotating_mouse: return
	
	var mouse_offset:Vector2 = get_viewport().get_mouse_position()
	mouse_offset = mouse_offset - mouse_last_position
	mouse_last_position = get_viewport().get_mouse_position()
	
	# Process Inputs
	camera_rotate_x.frame_acceleration += mouse_offset.y
	
	# Add acceleration to velocity and reset
	camera_rotate_x.velocity += camera_rotate_x.frame_acceleration * camera_rotate_x.acceleration_speed_factor
	camera_rotate_x.frame_acceleration = 0.0

	# Apply velocity and dampen
	# TODO: reenable y rotation on mouse
	#rotation.y += mouse_offset.x * camera_rotate_x.acceleration_speed_factor * delta # Remove comment to get y rotation on mouse
	camera_socket.rotation.x -= camera_rotate_x.velocity * delta
	camera_socket.rotation.x = clamp(camera_socket.rotation.x, camera_rotate_x.min_bound, camera_rotate_x.max_bound)
	camera_rotate_x.velocity *= _dampen_with_half_life(camera_rotate_x.velocity_half_life, delta)
	
	
# Rotates the camera base
func camera_base_rotate(delta:float) -> void:
	if !camera_can_rotate_base: return

	# Process Inputs
	if Input.is_action_pressed("camera_rotate_right"):
		camera_rotate_y.frame_acceleration -= 1
	elif Input.is_action_pressed("camera_rotate_left"):
		camera_rotate_y.frame_acceleration += 1
	
	# Add acceleration to velocity and reset
	camera_rotate_y.velocity += camera_rotate_y.frame_acceleration * camera_rotate_y.acceleration_speed_factor
	camera_rotate_y.frame_acceleration = 0.0
	
	# Apply velocity and dampen
	rotation.y += camera_rotate_y.velocity * delta
	camera_rotate_y.velocity *= _dampen_with_half_life(camera_rotate_y.velocity_half_life, delta)
	
	
# Pans the camera automatically based on screen margins
func camera_automatic_pan(delta:float) -> void:
	if !camera_can_automatic_pan: return
	
	var viewport_current:Viewport = get_viewport()
	var pan_direction:Vector2 = Vector2(-1,-1) # Starts negative
	var viewport_visible_rectangle:Rect2i = Rect2i(viewport_current.get_visible_rect())
	var viewport_size:Vector2i = viewport_visible_rectangle.size
	var current_mouse_position:Vector2 = viewport_current.get_mouse_position()
	var margin:float = camera_automatic_pan_margin # Shortcut var
	
	var zoom_factor:float = camera.position.z * 0.1
	
	# X pan
	if ((current_mouse_position.x < margin) or (current_mouse_position.x > viewport_size.x - margin)):
		if current_mouse_position.x > viewport_size.x/2.0:
			pan_direction.x = 1
		translate(Vector3(pan_direction.x * delta * camera_automatic_pan_speed * zoom_factor,0,0))
	
	# Y pan
	if ((current_mouse_position.y < margin) or (current_mouse_position.y > viewport_size.y - margin)):
		if current_mouse_position.y > viewport_size.y/2.0:
			pan_direction.y = 1
		translate(Vector3(0, 0, pan_direction.y * delta * camera_automatic_pan_speed * zoom_factor))
		
func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 2000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result = space.intersect_ray(ray_query)
	if !raycast_result.is_empty():
		province_selected.emit(Vector2(raycast_result.position.x,raycast_result.position.z))

# Helpers (Variant means float or vector)
var __NLOG2 = - log(2)
func _dampen_with_half_life(half_life:float, delta:float) -> Variant: # TODO: migrate to helper
	return exp(__NLOG2 * delta / half_life)
