extends BoxContainer

#
# Display of all geolayers and handling for z-index of geo-layers in the 2D space.
#


#@export var geo_layers: Node2D : 
	#set(new_geo_layers):
		#geo_layers = new_geo_layers
		#geolayer_visibility_changed.connect(
			#new_geo_layers.set_layer_visibility)
		#z_index_changed.connect(
			#new_geo_layers.reclassify_z_indices)


signal z_index_changed(item_array)
signal geolayer_visibility_changed(layer_name, is_visible)
