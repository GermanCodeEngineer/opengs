extends Node3D

signal province_selected

# Nodes
@onready var camera: Camera3D = $CameraSocket/Camera3D
@onready var camera_socket: Node3D = $CameraSocket
@onready var label_camera_position: Label = get_node_or_null("../ProvinceSelected/PanelContainer/GridContainer/LabelCameraPosition")

# Constants
var NLOG2 = - log(2)

##Camera move
#var camera_touchpad_move:Vector2 = Vector2.ZERO
#@export_range(0,1000,1) var camera_move_speed_xy:float = 500.0
#@export_range(0.01,1000,0.01) var camera_move_speed_reference_z:float = 100.0
#@export_range(0.01,10,0.01) var camera_move_speed_screen_scale_min:float = 0.01
#@export_range(0.01,1000000,0.01) var camera_move_speed_screen_scale_max:float = 1000000
#@export_range(0,2,0.01) var camera_move_speed_damp:float = 0.80
#
##Camera rotate
var camera_rotation_direction:float = 0
@export_range(0,10,0.1) var camera_rotation_speed:float = 0.20
@export_range(0,20,1) var camera_base_rotation_speed:float = 6
@export_range(0,10,1) var camera_socket_rotation_x_min:float = -1.60
@export_range(0,10,1) var camera_socket_rotation_x_max:float = -0.20
#
##Camera pan
#@export_range(0,32,4) var camera_automatic_pan_margin:int = 16
#@export_range(0,20,0.5) var camera_automatic_pan_speed:float = 18
#
##Camera zoom
#var camera_zoom_direction:float = 0
#@export_range(0,1000,1) var camera_zoom_speed:float = 500.0
#@export_range(0,100,1) var camera_zoom_min:float = 0.0
#@export_range(0,1000,1) var camera_zoom_max:float = 1000.0
#@export_range(0,2,0.01) var camera_zoom_speed_damp:float = 0.80

# Camera Movement # TODO: fine tune variables
var camera_acceleration_speed_xy_rel_to_z = 1.0
var camera_acceleration_speed_z = 100.0
var camera_pan_rel_acc_speed = 1.0
var camera_touchpad_rel_acc_speed = 1.0
var camera_magnify_rel_acc_speed = 1.0

var camera_velocity_half_life_xy = 0.10
var camera_velocity_half_life_z = camera_velocity_half_life_xy

# Camera Rotation # TODO: fine tune variables
var camera_rotation_acceleration_speed = 10.0
var camera_velocity_half_life_rotation = camera_velocity_half_life_xy

# Camera State
var camera_velocity = Vector3.ZERO
var frame_acceleration = Vector3.ZERO # Auto merged into velocity
var camera_rotation_velocity = Vector2.ZERO
var frame_rotation_acceleration = Vector2.ZERO # Auto merged into rotation velocity

# Bounds
var camera_minimum: Vector3 = Vector3(-460.0, -303.0, 10.0)
var camera_maximum: Vector3 = Vector3(460.0, 267.0, 1000.0)


# Flags
var camera_can_process:bool = true
var camera_can_move_base:bool = true
var camera_can_automatic_pan:bool = false
var camera_can_rotate_base:bool = false
var camera_can_rotate_socket_x:bool = false
var camera_can_rotate_by_mouse_offfset:bool = false

## Internal Flags
var camera_is_rotating_base:bool = false
var camera_is_rotating_mouse:bool = false
var mouse_last_position:Vector2 = Vector2.ZERO



func _ready() -> void:
	pass


func _round_vec(v: Vector3) -> Vector3:
	return Vector3(round(100 * v.x) / 100, round(100 * v.y) / 100, round(100 * v.z) / 100)

# Run each frame	
func _process(delta:float) -> void:
	if !camera_can_process: return
	camera_base_move(delta)
	if label_camera_position:
		label_camera_position.text = str(_round_vec(camera.position)) + " L|G " + str(_round_vec(camera.global_position))
	
	#print("Camera position:", camera.position, "|", "Global position:", camera.global_position)
	# Temporarily disable stuff
	# camera_automatic_pan(delta)
	camera_base_rotate(delta)
	# camera_rotate_to_mouse_offsets(delta)
	

# Handle Keyboard, Mouse, Touchpad Imports
func _unhandled_input(event: InputEvent) -> void:
	# Exit
	if Input.is_action_pressed("Exit"):
		get_tree().quit()
	
	## Camera Move
	if event is InputEventPanGesture: # TODO: test
		print("[DEBUG] PanGesture: ", event.delta)
		frame_acceleration += camera_pan_rel_acc_speed * Vector3(event.delta.x, event.delta.y, 0)
	
	
	# Camera Zoom
	if event.is_action("camera_zoom_in"):
		print("[DEBUG] Zoom In Event")
		frame_acceleration += Vector3(0, 0, - camera_touchpad_rel_acc_speed)
	elif event.is_action("camera_zoom_out"):
		print("[DEBUG] Zoom Out Event")
		frame_acceleration += Vector3(0, 0, camera_touchpad_rel_acc_speed)
	if event is InputEventMagnifyGesture: # TODO: test
		print("[DEBUG] MagnifyGesture: ", event.factor)
		frame_acceleration += Vector3(0, 0, camera_magnify_rel_acc_speed * (1 - event.factor))
	
	
	## Camera rotations
	
	#if event.is_action_pressed("camera_rotate_right"):
	#	frame_rotation_acceleration += Vector2(-1, 0) # scaled later
	#elif event.is_action_pressed("camera_rotate_left"):
	#	frame_rotation_acceleration += Vector2(1, 0) # scaled later
	if event.is_action_pressed("camera_rotate_right"):
		camera_rotation_direction = -1
		camera_is_rotating_base = true
		print("[DEBUG] Rotate Right Event")
	elif event.is_action_pressed("camera_rotate_left"):
		camera_rotation_direction = 1
		camera_is_rotating_base = true
		print("[DEBUG] Rotate Left Event")
	elif event.is_action_released("camera_rotate_left") or event.is_action_released("camera_rotate_right"):
		camera_is_rotating_base = false
		print("[DEBUG] Rotate Stop Event")
		
	#if event.is_action_pressed("camera_rotate"):
	#	mouse_last_position = get_viewport().get_mouse_position()
	#	camera_is_rotating_mouse = true
	#elif event.is_action_released("camera_rotate"):
	#	camera_is_rotating_mouse = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot_ray()


# Move and Zoom Camera
func camera_base_move(delta:float) -> void:
	if !camera_can_move_base: return
	
	# Calculate acceleration (move independent of camera rotation)
	if Input.is_action_pressed("camera_forward"):
		frame_acceleration += Vector3.UP
	if Input.is_action_pressed("camera_backward"):
		frame_acceleration -= Vector3.UP
	if Input.is_action_pressed("camera_right"):
		frame_acceleration += Vector3.RIGHT
	if Input.is_action_pressed("camera_left"):
		frame_acceleration -= Vector3.RIGHT
	
	# Scale acceleration by speed and delta
	# Move faster when camera is further away from map
	var z_multiplier = max(camera.position.z, camera_minimum.z)
	frame_acceleration.x *= camera_acceleration_speed_xy_rel_to_z * z_multiplier
	frame_acceleration.y *= camera_acceleration_speed_xy_rel_to_z * z_multiplier
	frame_acceleration.z *= camera_acceleration_speed_z
	frame_acceleration *= delta

	# Apply acceleration to velocity
	camera_velocity += frame_acceleration
	frame_acceleration = Vector3.ZERO

	# Apply velocity to camera position and clamp
	camera.position += camera_velocity
	var new_position = camera.position.clamp(camera_minimum, camera_maximum)
	# Stop movement if we hit a boundary
	if new_position.x != camera.position.x:
		camera_velocity.x = 0
	if new_position.y != camera.position.y:
		camera_velocity.y = 0
	if new_position.z != camera.position.z:
		camera_velocity.z = 0
	camera.position = new_position
	
	# Dampen velocity before next frame	var safe_half_life_xy = max(camera_velocity_half_life_xy, 0.0001)
	var damp_xy = exp(NLOG2 * delta / camera_velocity_half_life_xy)
	var damp_z  = exp(NLOG2 * delta / camera_velocity_half_life_z)
	camera_velocity.x *= damp_xy
	camera_velocity.y *= damp_xy
	camera_velocity.z *= damp_z


## Rotate the camera socket based on mouse offset
#func camera_rotate_to_mouse_offsets(delta:float) -> void:
#	if !camera_can_rotate_by_mouse_offfset or !camera_is_rotating_mouse: return
#	
#	var mouse_offset:Vector2 = get_viewport().get_mouse_position()
#	mouse_offset = mouse_offset - mouse_last_position
#	
#	mouse_last_position = get_viewport().get_mouse_position()
#	
#	#camera_base_rotate_left_right(delta,mouse_offset.x) #Remove comment to get y rotation on mouse
#	camera_socket_rotate_x(delta,mouse_offset.y)
	
	
# Rotates the camera base
func camera_base_rotate(delta:float) -> void:
	if !camera_can_rotate_base or !camera_is_rotating_base : return
	
	#To rotate
	camera_base_rotate_left_right(delta, camera_rotation_direction * camera_base_rotation_speed)

## Rotates the socket of the camera
#func camera_socket_rotate_x(delta:float, dir:float) -> void:
#	if !camera_can_rotate_socket_x  : return
#	
#	var new_rotation_x:float = <!question>camera_socket.rotation.x
#	new_rotation_x -= dir * delta * camera_rotation_speed
#	
#	new_rotation_x = clamp(new_rotation_x,camera_socket_rotation_x_min,camera_socket_rotation_x_max)
#	<!question>camera_socket.rotation.x = new_rotation_x
	
# Rotates the camera speed left or right
func camera_base_rotate_left_right(delta:float, dir:float) -> void:
	rotation.y += dir * camera_rotation_speed * delta
	
## Pans the camera automatically based on screen margins
#func camera_automatic_pan(delta:float) -> void:
#	if !camera_can_automatic_pan: return
#	
#	var viewport_current:Viewport = get_viewport()
#	var pan_direction:Vector2 = Vector2(-1,-1) #Starts negative
#	var viewport_visible_rectangle:Rect2i = Rect2i(viewport_current.get_visible_rect())
#	var viewport_size:Vector2i = viewport_visible_rectangle.size
#	var current_mouse_position:Vector2 = viewport_current.get_mouse_position()
#	var margin:float = camera_automatic_pan_margin #Shortcut var
#	
#	var zoom_factor:float = camera.position.z * 0.1
#	
#	#X pan
#	if ((current_mouse_position.x < margin) or (current_mouse_position.x > viewport_size.x - margin)):
#		if current_mouse_position.x > viewport_size.x/2.0:
#			pan_direction.x = 1
#		translate(Vector3(pan_direction.x * delta * camera_automatic_pan_speed * zoom_factor,0,0))
#	
#	#Y pan
#	if ((current_mouse_position.y < margin) or (current_mouse_position.y > viewport_size.y - margin)):
#		if current_mouse_position.y > viewport_size.y/2.0:
#			pan_direction.y = 1
#		translate(Vector3(0, 0, pan_direction.y * delta * camera_automatic_pan_speed * zoom_factor))
		
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
