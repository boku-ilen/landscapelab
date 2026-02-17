class_name LineSegment
extends MeshInstance3D


var feature

var start_transform
var end_transform
var mesh_length


func _ready():
	material_override = material_override.duplicate()
	apply_transform()


func apply_transform():
	material_override.set_shader_parameter("start", start_transform)
	material_override.set_shader_parameter("end", end_transform)
	material_override.set_shader_parameter("mesh_length", mesh_length)


func set_segment_start_end(new_start_transform, new_end_transform):
	start_transform = new_start_transform
	end_transform = new_end_transform


func set_mesh_length(new_length):
	mesh_length = new_length


# To be implemented by derived classes
func setup(new_feature):
	pass


# Should be overridden if the shader modifies e.g. the width of the mesh!
func get_mesh_aabb():
	return mesh.get_aabb()
