tool
extends Spatial

onready var mesh = get_node("Mesh")

func create(size, heightmap, texture, subdiv):
	mesh.set_size(size, subdiv)
	mesh.set_shader_param("tex", texture)
	mesh.set_shader_param("heightmap", heightmap)
	mesh.set_shader_param("subdiv", mesh.default_subdiv)
	mesh.set_shader_param("size", mesh.mesh_size)
	mesh.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	
	return mesh.size_without_skirt