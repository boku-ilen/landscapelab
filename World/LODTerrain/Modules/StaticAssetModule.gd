extends Module

#
# This module instantiates static assets by getting their information from the server
# and loading and placing them at the desired position.
# Static assets are assets which are spawned at a certain position and stay there, with
# no interaction with the client other than perhaps collisions. As opposed to other assets,
# they are not known to the client before, and instead loaded from DSCN files.
#

var asset_result

export(int) var asset_type_id
export(int) var render_layers


func _ready() -> void:
	tile.thread_task(self, "get_asset_data_from_server", [])


func _on_ready():
	if asset_result:
		for id in asset_result["assets"]:
			var obj = asset_result["assets"][id]
			
			# TODO: Remove absolute path once landscapelab-server issue #4 is fixed
			var name_path = "/media/boku/resources/buildings/importable/" + obj.modelpath + ".glb.dscn"
			
#			# For testing if not all buildings are available on the server:
#			var name_path = "/home/karl/Data/BOKU/retour-middleware/buildings/importable/Nockberge Testregion_0.gltf.glb.dscn"

			var dscn_node = load("res://addons/dscn_io/DSCN_Runtime_Node.gd").new()
			
			# Add a node which will be the root of the new asset 
			var asset_root = Spatial.new()
			add_child(asset_root)
			
			# Turn the absolute webmercator position from the server response into a relative local
			#  position at the correct height
			var abs_pos = [-obj.position[0], obj.position[1]]
			var local_pos = Offset.to_engine_coordinates(abs_pos)
			var ground_pos = WorldPosition.get_position_on_ground(Vector3(local_pos.x, 0, local_pos.y))
			
			if not ground_pos:
				logger.warning("No ground position could be obtained for asset of ID %d with position %d, %d"
					 % [asset_type_id, abs_pos[0], abs_pos[1]])
				continue
			
			# 'translation' is relative to the parent nodes. However, our ground_pos is in absolute coordinates.
			# Thus, we need to turn the ground_pos into a local position by subtracting the global origin.
			asset_root.translation = ground_pos - global_transform.origin
			
			# Load the DSCN file into the asset_root
			add_child(dscn_node)
			dscn_node.filepath = name_path
			dscn_node.path_to_node = asset_root.get_path()
			dscn_node.import_dscn()
			
			# Set the VisualLayer of the newly imported Asset
			set_render_layers(asset_root, render_layers)
	else:
		logger.warning("Couldn't get assets for ID %d!" % [asset_type_id])
			
	ready_to_be_displayed()


# Set the render layers of a node and all its children to the specified layer
# TODO: Is there a faster / more elegant way to do this?
func set_render_layers(node, layer):
	if node is VisualInstance:
		node.layers = layer
	
	for child in node.get_children():
		set_render_layers(child, layer)


func get_asset_data_from_server(d):
	asset_result = tile.get_texture_result("assetpos/get_all/%d" % [asset_type_id])
	
	make_ready()
