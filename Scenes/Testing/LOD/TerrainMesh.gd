tool
extends Spatial

#
# This script wraps a WorldMesh to create a TerrainMesh, used for heightmap terrain.
#

onready var mesh = get_node("Mesh")
onready var vegetation = get_node("Vegetation")

onready var tile = get_parent().get_parent()

# Create the terrain mesh
func _ready():
	var size = tile.size
	var heightmap = tile.heightmap
	var texture = tile.texture
	var subdiv_mod = tile.subdiv_mod
	var lod = tile.lod
	
	mesh.set_size(size, subdiv_mod)
	set_params(mesh, size, heightmap, texture, subdiv_mod)
	
	var num_children = vegetation.get_children().size()
	
	for grass in vegetation.get_children():
		if lod > 4:
			if lod > 6:
				grass.set_rows(40 / num_children)
				grass.set_spacing(size / 40 * num_children)
			else:
				grass.set_rows(30 / num_children)
				grass.set_spacing(size / 30 * num_children)
			set_params(grass.process_material, size, heightmap, texture, subdiv_mod)
			set_params(grass.material_override, size, heightmap, texture, subdiv_mod)
	
func set_params(obj, size, heightmap, texture, subdiv_mod):
	obj.set_shader_param("tex", texture)
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", mesh.default_subdiv * subdiv_mod)
	obj.set_shader_param("size", mesh.mesh_size)
	obj.set_shader_param("size_without_skirt", mesh.size_without_skirt)
	obj.set_shader_param("pos", transform.origin)