extends ChunkedLayerCompositionRenderer


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.texture_layer = layer_composition.render_info.texture_layer
