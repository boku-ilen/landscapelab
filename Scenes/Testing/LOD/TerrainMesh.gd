tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

onready var mesh = get_node("Mesh")

# Create the terrain mesh
func create(size, heightmap, texture, subdiv):
	mesh.set_size(size, subdiv)
	mesh.set_shader_param("tex", texture)
	mesh.set_shader_param("heightmap", heightmap)
	mesh.set_shader_param("subdiv", mesh.default_subdiv)
	mesh.set_shader_param("size", mesh.mesh_size)
	mesh.set_shader_param("size_without_skirt", mesh.size_without_skirt)