extends Node


var layers: Dictionary

signal new_rendered_layer
signal new_scored_layer
signal new_layer


func get_layer(name: String):
	return layers[name]


func add_layer(layer: Layer):
	layers[layer.name] = layer
	
	if layer.is_scored:
		emit_signal("new_scored_layer")
	if layer.is_rendered:
		emit_signal("new_rendered_layer")
	
	emit_signal("new_layer")
