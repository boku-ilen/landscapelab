class_name LineSegment
extends MeshInstance3D


var feature


func set_segment_start_end(start_transform, end_transform):
	material_override.set_shader_parameter("start", start_transform)
	material_override.set_shader_parameter("end", end_transform)


func set_mesh_length(new_length):
	material_override.set_shader_parameter("mesh_length", new_length)


# To be implemented by derived classes
func setup(new_feature):
	pass


# Should be overridden if the shader modifies e.g. the width of the mesh!
func get_mesh_aabb():
	return mesh.get_aabb()
