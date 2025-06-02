extends ChunkedLayerCompositionRenderer


func _ready():
	if layer_composition.render_info.chunk_size: chunk_size = layer_composition.render_info.chunk_size
	if layer_composition.render_info.extent: extent = layer_composition.render_info.extent
	
	super._ready()


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.ground_height_layer
	chunk.object_layer = layer_composition.render_info.geo_feature_layer
	chunk.objects_mapping = layer_composition.render_info.meshes
	chunk.selector_attribute_name = layer_composition.render_info.selector_attribute_name
	chunk.randomize = layer_composition.render_info.randomize
