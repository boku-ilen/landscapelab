extends ChunkedLayerCompositionRenderer


func _ready():
	if layer_composition.render_info.chunk_size: chunk_size = layer_composition.render_info.chunk_size
	if layer_composition.render_info.extent: extent = layer_composition.render_info.extent
	
	super._ready()


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.ground_height_layer
	chunk.object_layer = layer_composition.render_info.geo_feature_layer
	chunk.object = load(layer_composition.render_info.object)
	chunk.randomize = layer_composition.render_info.randomize
