extends Configurator


var renderers = {
	LayerComposition.RenderType.BASIC_TERRAIN: preload("res://Layers/Renderers/Terrain/BasicTerrainRenderer.tscn"),
	LayerComposition.RenderType.REALISTIC_TERRAIN: preload("res://Layers/Renderers/Terrain/RealisticTerrainRenderer.tscn"),
	LayerComposition.RenderType.POLYGON: preload("res://Layers/Renderers/Polygon/PolygonRenderer.tscn"),
	LayerComposition.RenderType.VEGETATION: preload("res://Layers/Renderers/RasterVegetation/RasterVegetationRenderer.tscn"),
	LayerComposition.RenderType.OBJECT: preload("res://Layers/Renderers/Objects/ObjectRenderer.tscn"),
	LayerComposition.RenderType.PATH: preload("res://Layers/Renderers/Path/PathRenderer.tscn"),
	LayerComposition.RenderType.CONNECTED_OBJECT: preload("res://Layers/Renderers/ConnectedObjects/ConnectedObjectRenderer.tscn"),
	LayerComposition.RenderType.TWODIMENSIONAL: preload("res://Layers/Renderers/2DLayer/2DLayerRenderer.tscn"),
	LayerComposition.RenderType.POLYGON_OBJECT: preload("res://Layers/Renderers/PolygonObject/PolygonObjectRenderer.tscn")
}


var layer_composition_renderer = preload("res://Layers/LayerCompositionRenderer.tscn")

const LOG_MODULE := "LAYERCONFIGURATION"

@onready var layer_composition_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	# There may be some rendered layers which were added before this _ready.
	for layer_composition in Layers.get_rendered_layer_compositions():
		add_layer_composition(layer_composition)
	
	# For future layers, use a signal.
	Layers.connect("new_rendered_layer_composition",Callable(self,"add_layer_composition"))
	Layers.connect("removed_rendered_layer_composition",Callable(self,"remove_layer_composition"))


func add_layer_composition(layer_composition: LayerComposition):
	if not renderers.has(layer_composition.render_type):
		logger.error("Unknown render type for rendered layer: %s" % [str(layer_composition.render_type)], LOG_MODULE)
		return
	
	var new_layer_composition = renderers[layer_composition.render_type].instantiate()
	
	new_layer_composition.layer_composition = layer_composition
	new_layer_composition.name = layer_composition.name
	
	layer_composition_renderers.add_child(new_layer_composition)


func remove_layer(name_to_remove):
	layer_composition_renderers.get_node(name_to_remove).queue_free()
