extends ChunkedLayerCompositionRenderer

var refine_load_distance


func _ready():
	chunk_size = layer_composition.render_info.chunk_size
	extent = layer_composition.render_info.extent
	refine_load_distance = layer_composition.render_info.detail_distance
	
	if "scene" in layer_composition.render_info.objects.values().front().keys():
		# Use the Scene-based renderer
		chunk_scene = load("res://Layers/Renderers/ScatteredObject/ScatteredObjectsScene.tscn")
	else:
		# Use the MultiMesh-based renderer
		chunk_scene = load("res://Layers/Renderers/ScatteredObject/ScatteredObjectsMultiMesh.tscn")
	
	super._ready()


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer
	chunk.scatter_layer = layer_composition.render_info.scatter_layer
	chunk.objects = layer_composition.render_info.objects
	chunk.refine_load_distance = refine_load_distance
