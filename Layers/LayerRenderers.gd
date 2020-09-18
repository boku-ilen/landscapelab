extends Configurator


var layer_renderer = preload("res://Layers/LayerRenderer.tscn")
var terrain_renderer = preload("res://Layers/Renderers/TerrainRenderer.tscn")

onready var layer_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	# There may be some rendered layers which were added before this _ready.
	for layer in Layers.get_rendered_layers():
		add_layer(layer)
	
	# For future layers, use a signal.
	Layers.connect("new_rendered_layer", self, "add_layer")


func add_layer(layer: Layer):
	var new_layer
	
	if "render_as" in layer.fields:
		if layer.fields["render_as"] == "terrain":
			new_layer = terrain_renderer.instance()
	else:		
		new_layer = layer_renderer.instance()
	
	new_layer.layer = layer
	layer_renderers.add_child(new_layer)
	
	return true
