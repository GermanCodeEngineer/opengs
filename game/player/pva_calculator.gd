extends RefCounted
class_name PVACalculator # Dataclass to calculate an acceleration, velocity and position system

# Variant refers to a float or a vector here
# Constant
var acceleration_speed_factor: Variant
var velocity_half_life: float
var min_bound: Variant
var max_bound: Variant

# Changing
var velocity: Variant
var frame_acceleration: Variant # Auto merged into velocity, reset each frame

func _init(_acceleration_speed_factor, _velocity_half_life: float, _min_bound, _max_bound, start_velocity, start_frame_acceleration):
	acceleration_speed_factor = _acceleration_speed_factor
	velocity_half_life = _velocity_half_life
	min_bound = _min_bound
	max_bound = _max_bound
	velocity = start_velocity
	frame_acceleration = start_frame_acceleration

