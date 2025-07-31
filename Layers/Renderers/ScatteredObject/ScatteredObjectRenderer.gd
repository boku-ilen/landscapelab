extends ChunkedLayerCompositionRenderer


func _ready():
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
