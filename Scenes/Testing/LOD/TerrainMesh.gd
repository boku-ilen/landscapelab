tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

onready var mesh = get_node("Mesh")
onready var grass = get_node("Grass")

onready var tile = get_parent().get_parent()

# Create the terrain mesh
func _ready():
	var size = tile.size
	var heightmap = tile.heightmap
	var texture = tile.texture
	var subdiv_mod = tile.subdiv_mod
	var lod = tile.lod
	
	# TODO: This currently receives a heightmap and texture. In reality, it will instead get a position, and then fetch the heightmap on its own.
	mesh.set_size(size, subdiv_mod)
	set_params(mesh, size, heightmap, texture, subdiv_mod)
	
	if lod > 5:
		grass.set_rows(150)
		grass.set_spacing(size / 100)
		set_params(grass.process_material, size, heightmap, texture, subdiv_mod)
	
func set_params(obj, size, heightmap, texture, subdiv_mod):
	obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv * subdiv_mod)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)