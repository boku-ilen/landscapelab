extends LayerRenderer


var renderers


# Called when the node enters the scene tree for the first time.
func load_new_data():
	renderers = Vegetation.get_renderers()
	
	for renderer in renderers.get_children():
		renderer.update_textures(layer.render_info.height_layer, layer.render_info.landuse_layer,
				center[0], center[1])


func apply_new_data():
	for renderer in renderers.get_children():
		renderer.apply_data()
	
	add_child(renderers)
