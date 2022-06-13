extends Node

var geo_layers: Dictionary = { "rasters": {}, "features": {}}
var layers: Dictionary

signal new_rendered_layer(layer)
signal new_scored_layer(layer)
signal new_layer(layer)
signal new_geo_layer(geo_layer, is_raster)
signal removed_rendered_layer(layer_name, render_type)
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
	
	# FIXME: is there any way to find out whether something is raster or feature
	# FIXME: from the resource? 
	for geo_layer in layer.render_info.get_geolayers():
		add_geo_layer(geo_layer, true)
	
	if layer.is_scored:
		emit_signal("new_scored_layer", layer)
	if is_layer_rendered(layer):
		emit_signal("new_rendered_layer", layer)
	
	emit_signal("new_layer", layer)


func add_geo_layer(layer: Resource, is_raster: bool):
	if layer:
		if is_raster:
			geo_layers["rasters"][layer.resource_name] = layer
		else: 
			geo_layers["features"][layer.resource_name] = layer
		
		emit_signal("new_geo_layer", is_raster)


func remove_layer(layer_name: String):
	if layers[layer_name].is_scored:
		emit_signal("removed_scored_layer", layer_name)
	if is_layer_rendered(layers[layer_name]):
		emit_signal("removed_rendered_layer", layer_name, layers[layer_name].render_type)
	
	emit_signal("removed_layer", layer_name)
	
	layers.erase(layer_name)


func is_layer_rendered(layer: Layer):
	return layer.render_type > Layer.RenderType.NONE


func is_layer_of_type(layer: Layer, type):
	return layer.render_type == type
