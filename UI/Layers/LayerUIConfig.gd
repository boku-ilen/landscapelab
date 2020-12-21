extends Configurator


var layer_widget = preload("res://UI/Layers/LayerWidget.tscn")

onready var layer_container = get_parent().get_node("VBoxContainer/ScrollLayers/LayerContainer")


func _ready():
	Layers.connect("new_layer", self, "add_layer")
	Layers.connect("removed_layer", self, "remove_layer")


func add_layer(layer: Layer):
	var new_layer = layer_widget.instance()
	new_layer.layer = layer
	new_layer.name = layer.name
	# hocus pocus
	layer_container.add_child(new_layer)
	
	return true


func remove_layer(layer_name: String):
	layer_container.get_node(layer_name).queue_free()
	
	return true
