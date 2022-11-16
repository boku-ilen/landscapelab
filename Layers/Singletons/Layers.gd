extends Node

var geo_layers: Dictionary = { "rasters": {}, "features": {}}
var layer_compositions: Dictionary

signal new_rendered_layer_composition(layer_composition)
signal new_scored_layer_composition(layer_composition)
signal new_layer_composition(layer_composition)
signal new_geo_layer(geo_layer, is_raster)
signal removed_rendered_layer_composition(layer_composition_name, render_type)
signal removed_scored_layer_composition(layer_composition_name)
signal removed_layer_composition(layer_composition_name)

const LOG_MODULE := "LAYERCONFIGURATION"


func get_layer_composition(name: String):
	return layer_compositions[name] if layer_compositions.has(name) else null


func get_rendered_layer_compositions():
	var returned_layers = []
	
	for layer_composition in layer_compositions:
		if is_layer_composition_rendered(layer_composition):
			returned_layers.append(layer_composition)
	
	return returned_layers


func get_layer_compositions_of_type(type):
	var returned_layers = []
	
	for layer_composition in layer_compositions:
		if is_layer_composition_of_type(layer_compositions[layer_composition], type):
			returned_layers.append(layer_compositions[layer_composition])
	
	return returned_layers


func add_layer_composition(layer_composition: LayerComposition):
	layer_compositions[layer_composition.name] = layer_composition
	
	for geo_layer in layer_composition.render_info.get_geolayers():
		add_geo_layer(geo_layer)
	
	if layer_composition.is_scored:
		emit_signal("new_scored_layer_composition", layer_composition)
	if is_layer_composition_rendered(layer_composition):
		emit_signal("new_rendered_layer_composition", layer_composition)
	
	emit_signal("new_layer_composition", layer_composition)


func add_geo_layer(layer: Resource):
	if layer is GeoRasterLayer:
		geo_layers["rasters"][layer.resource_name] = layer
	elif layer is GeoFeatureLayer:
		geo_layers["features"][layer.resource_name] = layer
	else:
		logger.error("Added an invalid geolayer", LOG_MODULE)
		return
		
	emit_signal("new_geo_layer", layer is GeoRasterLayer)


func remove_layer_composition(layer_composition_name: String):
	if layer_compositions[layer_composition_name].is_scored:
		emit_signal("removed_scored_layer_composition", layer_composition_name)
	if is_layer_composition_rendered(layer_compositions[layer_composition_name]):
		emit_signal("removed_rendered_layer_composition", layer_composition_name, layer_compositions[layer_composition_name].render_type)
	
	emit_signal("removed_layer_composition", layer_composition_name)
	
	layer_compositions.erase(layer_composition_name)


func is_layer_composition_rendered(layer_composition: LayerComposition):
	return layer_composition.render_type > LayerComposition.RenderType.NONE


func is_layer_composition_of_type(layer_composition: LayerComposition, type):
	return layer_composition.render_type == type
