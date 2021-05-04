extends LayerRenderer


# Called when the node enters the scene tree for the first time.
func load_new_data():
	var renderers = Vegetation.get_renderers()
	add_child(renderers)
	
	for renderer in renderers.get_children():
		renderer.update_textures(layer.render_info.height_layer, layer.render_info.landuse_layer,
				center[0], center[1])


# TODO: Add apply_new_data for actually visualizing the data (thread-safety)
