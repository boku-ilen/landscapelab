extends ChunkedLayerCompositionRenderer


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.ground_height_layer
	chunk.object_layer = layer_composition.render_info.geo_feature_layer
	chunk.object = load(layer_composition.render_info.object)
