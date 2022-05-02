extends Configurator

export var position_manager_path: NodePath

var layer_widget = preload("res://UI/Layers/LayerConfiguration/LayerWidget.tscn")

onready var layer_container = get_parent().get_node("VBoxContainer/ScrollLayers/LayerContainer")
onready var position_manager = get_node(position_manager_path)

func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer in Layers.layers:
		add_layer(Layers.layers[layer])
		
	Layers.connect("new_layer", self, "add_layer")
	Layers.connect("removed_layer", self, "remove_layer")


func add_layer(layer: Layer):
	var new_layer = layer_widget.instance()
	new_layer.layer = layer
	new_layer.name = layer.name
	# hocus pocus
	layer_container.add_child(new_layer)
	
	new_layer.connect("translate_to_layer", position_manager, "set_offset")
	
	return true


func remove_layer(layer_name: String):
	layer_container.get_node(layer_name).queue_free()
	
	return true
