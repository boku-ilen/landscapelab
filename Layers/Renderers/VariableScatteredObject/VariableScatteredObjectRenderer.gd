extends ChunkedLayerCompositionRenderer

var refine_load_distance
var weather_manager: WeatherManager

# TODO: Adapt, currently copypasta


func _ready():
	chunk_size = layer_composition.render_info.chunk_size
	extent = layer_composition.render_info.extent
	refine_load_distance = layer_composition.render_info.detail_distance
	chunk_scene = load("res://Layers/Renderers/VariableScatteredObject/VariableScatteredObjects.tscn")
	
	super._ready()


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer

	chunk.placement_formula = layer_composition.render_info.placement_formula
	chunk.placement_inputs = layer_composition.render_info.placement_inputs

	chunk.placement_min_radius = 1.0
	chunk.placement_max_radius = 10.0 # FIXME

	chunk.probability_layer = layer_composition.render_info.probability_layer
	chunk.meshes = layer_composition.render_info.meshes

	chunk.scale_layer = layer_composition.render_info.scale_layer
	
	chunk.weather_manager = weather_manager
