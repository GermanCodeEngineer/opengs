extends Node3D
signal province_selected

# Nodes
@onready var camera: Camera3D = $CameraSocket/Camera3D
@onready var camera_socket: Node3D = $CameraSocket

# Control variables # TODO: fine tune
# Camera Movement
class MovementCalculator extends PVACalculator:
	pass

var camera_move := MovementCalculator.new(
	Vector3(50.0, 50.0, 50.0), # acceleration_speed_factor
	0.15, # velocity_half_life
	Vector3(-INF, -INF, -INF), # min_bound # TODO: calculate bounds?
	Vector3(INF, INF, INF), # max_bound
	Vector3.ZERO, # start_velocity
	Vector3.ZERO, # start_frame_acceleration
)
var camera_touchpad_move:Vector2 = Vector2.ZERO

# Camera Rotation to Mouse Offsets on X and Y
class MouseRotationCalculator extends PVACalculator:
	pass

var camera_rotate_mouse := MouseRotationCalculator.new(
	Vector2(0.2, 0.2), # acceleration_speed_factor
	0.00, # velocity_half_life (velocity immediately reset)
	Vector2(deg_to_rad(-90), -INF), # min_bound
	Vector2(deg_to_rad(-15), INF), # max_bound
	Vector2.ZERO, # start_velocity
	Vector2.ZERO, # start_frame_acceleration
)


# Camera Rotation to Keys on X and Y
class KeysRotationCalculator extends PVACalculator:
	pass

var camera_rotate_keys := KeysRotationCalculator.new(
	Vector2(1.2, 1.2), # acceleration_speed_factor
	0.15, # velocity_half_life
	Vector2(deg_to_rad(-90), -INF), # min_bound
	Vector2(deg_to_rad(-15), INF), # max_bound
	Vector2.ZERO, # start_velocity
	Vector2.ZERO, # start_frame_acceleration
)

# Camera Zooming
class ZoomCalculator extends PVACalculator:
	pass

var camera_zoom := ZoomCalculator.new(
	300.0, # acceleration_speed_factor
	0.15, # velocity_half_life
	10.0, # min_bound
	1000.0, # max_bound
	0.0, # start_velocity
	0.0, # start_frame_acceleration
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
	camera_rotate_to_keys(delta)
	camera_rotate_to_mouse_offsets(delta)
	_show_fps()

# Show FPS on the window
func _show_fps():
	var fps = Engine.get_frames_per_second()
	var label_text = "FPS: %d  Rot: (X: %.1fr, Y: %.1fr)" % [fps, camera_socket.rotation.x, rotation.y]
	if not has_node("FPSLabel"):
		var label = Label.new()
		label.name = "FPSLabel"
		label.text = label_text
		label.set_position(Vector2(10, 10))
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.add_theme_color_override("font_color", Color(1,1,0))
		add_child(label)
	else:
		var label = get_node("FPSLabel")
		label.text = label_text


# Moves the base of camera
func camera_base_move(delta:float) -> void:
	if !camera_can_move_base: return

	# Process Inputs
	if Input.is_action_pressed("camera_move_forward"): camera_move.frame_acceleration -= transform.basis.z
	if Input.is_action_pressed("camera_move_backward"): camera_move.frame_acceleration += transform.basis.z
	if Input.is_action_pressed("camera_move_right"): camera_move.frame_acceleration += transform.basis.x
	if Input.is_action_pressed("camera_move_left"): camera_move.frame_acceleration -= transform.basis.x
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
	
	# Left Click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot_ray()


	# Camera Move
	if event is InputEventPanGesture: # TODO: test
		camera_touchpad_move = event.delta
	
	# Camera Zoom
	if event.is_action_pressed("camera_zoom_in"):
		camera_zoom.frame_acceleration -= 1
	elif  event.is_action_pressed("camera_zoom_out"):
		camera_zoom.frame_acceleration += 1
	if event is InputEventMagnifyGesture: # TODO: test if possible (touchpad does not register as this)
		camera_zoom.frame_acceleration += (1-event.factor)
	
	# Camera Rotation
	if event.is_action_pressed("camera_rotate_mouse"):
		mouse_last_position = get_viewport().get_mouse_position()
		camera_is_rotating_mouse = true
	elif event.is_action_released("camera_rotate_mouse"):
		camera_is_rotating_mouse = false


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
	
	var mouse_offset := get_viewport().get_mouse_position()
	mouse_offset = mouse_offset - mouse_last_position
	mouse_last_position = get_viewport().get_mouse_position()
	
	# Process Inputs
	camera_rotate_mouse.frame_acceleration.x += mouse_offset.y # This invertion is intentional
	camera_rotate_mouse.frame_acceleration.y += mouse_offset.x

	# Add acceleration to velocity and reset
	camera_rotate_mouse.velocity += camera_rotate_mouse.frame_acceleration * camera_rotate_mouse.acceleration_speed_factor
	camera_rotate_mouse.frame_acceleration = Vector2.ZERO

	# Apply velocity, dampen and clamp to bounds
	var rot := Vector2(camera_socket.rotation.x, rotation.y)
	rot -= camera_rotate_mouse.velocity * delta
	rot = rot.clamp(camera_rotate_mouse.min_bound, camera_rotate_mouse.max_bound)
	camera_socket.rotation.x = rot.x
	rotation.y = rot.y
	camera_rotate_mouse.velocity *= _dampen_with_half_life(camera_rotate_mouse.velocity_half_life, delta)
	
	
# Rotates the camera base
func camera_rotate_to_keys(delta:float) -> void:
	if !camera_can_rotate_base: return

	# Process Inputs
	if Input.is_action_pressed("camera_rotate_right"):
		camera_rotate_keys.frame_acceleration += Vector2(0, -1)
	elif Input.is_action_pressed("camera_rotate_left"):
		camera_rotate_keys.frame_acceleration += Vector2(0, 1)
	if Input.is_action_pressed("camera_rotate_up"):
		camera_rotate_keys.frame_acceleration += Vector2(-1, 0)
	elif Input.is_action_pressed("camera_rotate_down"):
		camera_rotate_keys.frame_acceleration += Vector2(1, 0)
	
	# Add acceleration to velocity and reset
	camera_rotate_keys.velocity += camera_rotate_keys.frame_acceleration * camera_rotate_keys.acceleration_speed_factor
	camera_rotate_keys.frame_acceleration = Vector2.ZERO
	
	# Apply velocity and dampen
	var rot := Vector2(camera_socket.rotation.x, rotation.y)
	rot -= camera_rotate_keys.velocity * delta
	rot = rot.clamp(camera_rotate_keys.min_bound, camera_rotate_keys.max_bound)
	camera_socket.rotation.x = rot.x
	rotation.y = rot.y
	camera_rotate_keys.velocity *= _dampen_with_half_life(camera_rotate_keys.velocity_half_life, delta)
	
	
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
	if half_life == 0: return 0 # Fully reset velocity if half_life is 0
	return exp(__NLOG2 * delta / half_life)
