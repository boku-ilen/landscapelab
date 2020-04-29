extends Module

#
# This module fetches the topomap for its tile, to be displayed on the minimap.
#

func init(data=null):
	var mesh = get_node("MeshInstance")
	
	mesh.mesh = tile.create_tile_plane_mesh()
	
	var topo = tile.get_texture("topomap")
	mesh.material_override.albedo_texture = topo
	
	_done_loading()
