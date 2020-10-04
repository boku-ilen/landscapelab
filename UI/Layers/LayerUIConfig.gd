extends Configurator


var layer_widget = preload("res://UI/Layers/LayerWidget.tscn")

onready var layer_container = get_parent().get_node("VBoxContainer/ScrollLayers/LayerContainer")


func _ready():
	Layers.connect("new_layer", self, "add_layer")


func add_layer(layer: Layer):
	var new_layer = layer_widget.instance()
	new_layer.layer = layer
	# hocus pocus
	layer_container.add_child(new_layer)
	
	return true
