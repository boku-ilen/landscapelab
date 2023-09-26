extends ChunkedLayerCompositionRenderer


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.plant_layer = layer_composition.render_info.plant_layer
