tool
extends Module

#
# This module fetches the heightmap from its tile and a texture to create terrain using a shader.
#

var grass_tex = preload("res://Resources/Textures/grass-ground.jpg") # TODO: Testing only! In the future, this texture will be fetched from the server.

onready var mesh = get_node("MeshInstance")

func _ready():
	mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(mesh.material_override)
	
	# TODO: Actually fetch the right texture
	mesh.material_override.set_shader_param("tex", grass_tex)
	
	done_loading()