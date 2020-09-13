extends Configurator


var layer_renderer = preload("res://Layers/LayerRenderer.tscn")

onready var layer_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	Layers.connect("new_rendered_layer", self, "add_layer")


func add_layer(layer: Layer):
	var new_layer = layer_renderer.instance()
	new_layer.layer = layer
	# hocus pocus
	layer_renderers.add_child(new_layer)
	
	return true
