extends Node

var geo_layers: Dictionary
var layers: Dictionary

signal new_rendered_layer(layer)
signal new_scored_layer(layer)
signal new_layer(layer)
signal removed_rendered_layer(layer_name)
signal removed_scored_layer(layer_name)
signal removed_layer(layer_name)


func get_layer(name: String):
	return layers[name] if layers.has(name) else null


func get_rendered_layers():
	var returned_layers = []
	
	for layer in layers:
		if is_layer_rendered(layer):
			returned_layers.append(layer)
	
	return returned_layers


func get_layers_of_type(type):
	var returned_layers = []
	
	for layer in layers:
		if is_layer_of_type(layers[layer], type):
			returned_layers.append(layers[layer])
	
	return returned_layers


func add_layer(layer: Layer):
	layers[layer.name] = layer
	
	if layer.is_scored:
		emit_signal("new_scored_layer", layer)
	if is_layer_rendered(layer):
		emit_signal("new_rendered_layer", layer)
	
	emit_signal("new_layer", layer)


func remove_layer(layer_name: String):
	if layers[layer_name].is_scored:
		emit_signal("removed_scored_layer", layer_name)
	if is_layer_rendered(layers[layer_name]):
		emit_signal("removed_rendered_layer", layer_name)
	
	emit_signal("removed_layer", layer_name)
	
	layers.erase(layer_name)


func is_layer_rendered(layer: Layer):
	return layer.render_type > Layer.RenderType.NONE


func is_layer_of_type(layer: Layer, type):
	return layer.render_type == type
