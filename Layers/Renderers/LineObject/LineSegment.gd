class_name LineSegment
extends MeshInstance3D


var feature


func set_segment_start_end(start_transform, end_transform):
	material_override.set_shader_parameter("start", start_transform)
	material_override.set_shader_parameter("end", end_transform)


# To be implemented by derived classes
func setup(new_feature):
	pass


func set_mesh_length(new_length):
	material_override.set_shader_parameter("mesh_length", new_length)
