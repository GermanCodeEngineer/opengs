extends Node3D

# Line3D draws a 3D line between two points with customizable color and width.
# Usage: Add this node to your scene and set the start, end, color, and width properties.

@export var start: Vector3 = Vector3.ZERO
@export var end: Vector3 = Vector3(0, 0, 1)
@export var color: Color = Color(1, 1, 1)
@export var width: float = 0.05

var _mesh_instance: MeshInstance3D

func _ready():
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	_update_line()

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_line()

func _update_line():
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var dir = (end - start).normalized()
	var up = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var right = dir.cross(up).normalized() * width * 0.5
	# Two quads for thickness
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(start - right)
	mesh.surface_add_vertex(start + right)
	mesh.surface_add_vertex(end - right)
	mesh.surface_add_vertex(end + right)
	mesh.surface_end()
	_mesh_instance.mesh = mesh

func set_points(p_start: Vector3, p_end: Vector3):
	start = p_start
	end = p_end
	_update_line()

func set_color(p_color: Color):
	color = p_color
	_update_line()

func set_width(p_width: float):
	width = p_width
	_update_line()
