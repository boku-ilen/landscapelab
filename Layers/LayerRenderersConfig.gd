extends Configurator


var renderers = {
	Layer.RenderType.BASIC_TERRAIN: preload("res://Layers/Renderers/Terrain/BasicTerrainRenderer.tscn"),
	Layer.RenderType.REALISTIC_TERRAIN: preload("res://Layers/Renderers/Terrain/RealisticTerrainRenderer.tscn"),
	Layer.RenderType.POLYGON: preload("res://Layers/Renderers/Polygon/PolygonRenderer.tscn"),
	Layer.RenderType.VEGETATION: preload("res://Layers/Renderers/RasterVegetation/RasterVegetationRenderer.tscn"),
	Layer.RenderType.OBJECT: preload("res://Layers/Renderers/Objects/ObjectRenderer.tscn"),
	Layer.RenderType.PATH: preload("res://Layers/Renderers/Path/PathRenderer.tscn"),
	Layer.RenderType.CONNECTED_OBJECT: preload("res://Layers/Renderers/ConnectedObjects/ConnectedObjectRenderer.tscn"),
	Layer.RenderType.TWODIMENSIONAL: preload("res://Layers/Renderers/2DLayer/2DLayerRenderer.tscn"),
	Layer.RenderType.POLYGON_OBJECT: preload("res://Layers/Renderers/PolygonObject/PolygonObjectRenderer.tscn")
}


var layer_renderer = preload("res://Layers/LayerRenderer.tscn")

const LOG_MODULE := "LAYERCONFIGURATION"

onready var layer_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	# There may be some rendered layers which were added before this _ready.
	for layer in Layers.get_rendered_layers():
		add_layer(layer)
	
	# For future layers, use a signal.
	Layers.connect("new_rendered_layer", self, "add_layer")
	Layers.connect("removed_rendered_layer", self, "remove_layer")


func add_layer(layer: Layer):
	if not renderers.has(layer.render_type):
		logger.error("Unknown render type for rendered layer: %s" % [str(layer.render_type)], LOG_MODULE)
		return
	
	var new_layer = renderers[layer.render_type].instance()
	
	new_layer.layer = layer
	new_layer.name = layer.name
	
	layer_renderers.add_child(new_layer)


func remove_layer(name_to_remove):
	layer_renderers.get_node(name_to_remove).queue_free()
