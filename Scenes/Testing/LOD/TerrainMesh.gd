tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

onready var mesh = get_node("Mesh")
onready var grass = get_node("Grass")

# Create the terrain mesh
func create(size, heightmap, texture, subdiv, lod):
	# TODO: This currently receives a heightmap and texture. In reality, it will instead get a position, and then fetch the heightmap on its own.
	mesh.set_size(size, subdiv)
	set_params(mesh, size, heightmap, texture, subdiv)
	
	if lod > 5:
		grass.set_rows(150)
		grass.set_spacing(size / 100)
		set_params(grass.process_material, size, heightmap, texture, subdiv)
	
func set_params(obj, size, heightmap, texture, subdiv):
	obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	