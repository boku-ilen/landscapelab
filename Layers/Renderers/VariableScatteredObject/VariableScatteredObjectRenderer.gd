extends ChunkedLayerCompositionRenderer

var refine_load_distance
var weather_manager: WeatherManager

var preloaded_meshes = {}
var preloaded_spritesheets_albedo = {}
var preloaded_spritesheets_normal = {}


func _ready():
	chunk_size = layer_composition.render_info.chunk_size
	extent = layer_composition.render_info.extent
	refine_load_distance = layer_composition.render_info.detail_distance
	chunk_scene = load("res://Layers/Renderers/VariableScatteredObject/VariableScatteredObjects.tscn")
	
	# Preload meshes and create spritesheets
	for mesh_name in layer_composition.render_info.meshes.keys():
		var mesh_path = layer_composition.render_info.meshes[mesh_name]["mesh"]
		
		preloaded_meshes[mesh_path] = load(mesh_path)
		var spritesheet = BillboardSpritesheetGenerator.create_billboard_sprites_for_mesh(preloaded_meshes[mesh_path])
		
		preloaded_spritesheets_albedo[mesh_path] = ImageTexture.create_from_image(spritesheet[0])
		preloaded_spritesheets_normal[mesh_path] = ImageTexture.create_from_image(spritesheet[1])
	
	super._ready()


func custom_chunk_setup(chunk):
	chunk.height_layer = layer_composition.render_info.height_layer

	chunk.placement_formula = layer_composition.render_info.placement_formula
	chunk.placement_inputs = layer_composition.render_info.placement_inputs

	chunk.placement_min_radius = layer_composition.render_info.placement_min_radius
	chunk.placement_max_radius = layer_composition.render_info.placement_max_radius

	chunk.probability_layer = layer_composition.render_info.probability_layer
	chunk.meshes = layer_composition.render_info.meshes
	
	chunk.preloaded_meshes = preloaded_meshes
	chunk.preloaded_spritesheets_albedo = preloaded_spritesheets_albedo
	chunk.preloaded_spritesheets_normal = preloaded_spritesheets_normal

	chunk.scale_layer = layer_composition.render_info.scale_layer
	chunk.griddedness_layer = layer_composition.render_info.griddedness_layer
	
	chunk.weather_manager = weather_manager
