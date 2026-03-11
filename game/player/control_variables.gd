extends RefCounted
class_name ControlVariables # Dataclass to store variables together in a bundle

# Variant refers to a float or a vector here
# Constant
var acceleration_speed_factor: Variant
var velocity_half_life: Variant

# Changing
var velocity: Variant
var frame_acceleration: Variant # Auto merged into velocity, reset each frame

func _init(_acceleration_speed_factor, _velocity_half_life, _velocity, _frame_acceleration):
	acceleration_speed_factor = _acceleration_speed_factor
	velocity_half_life = _velocity_half_life
	velocity = _velocity
	frame_acceleration = _frame_acceleration

