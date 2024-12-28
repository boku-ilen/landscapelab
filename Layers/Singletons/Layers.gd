extends Node

var crs
var current_center := Vector3.ZERO
var geo_layers: Dictionary = { "rasters": {}, "features": {}}
var layer_compositions: Dictionary

signal new_rendered_layer_composition(layer_composition)
signal new_scored_layer_composition(layer_composition)
signal new_layer_composition(layer_composition)
signal new_geo_layer(geo_layer)
signal removed_rendered_layer_composition(layer_composition_name, render_info)
signal removed_scored_layer_composition(layer_composition_name)
signal removed_layer_composition(layer_composition_name)


func get_layer_composition(lc_name: String):
	return layer_compositions[lc_name] if layer_compositions.has(lc_name) else null


func get_layers_with_render_info(render_info_class: Variant):
	var returned_layers = []
	
	for layer_composition in layer_compositions:
		if is_instance_of(layer_composition.render_info, render_info_class):
			returned_layers.append(layer_composition)
	
	return returned_layers


func get_rendered_layer_compositions():
	var returned_layers = []
	
	for layer_composition in layer_compositions:
		if is_layer_composition_rendered(layer_composition):
			returned_layers.append(layer_composition)
	
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


func add_geo_layer(layer: RefCounted):
	if layer is GeoRasterLayer:
		geo_layers["rasters"][layer.get_file_info()["name"]] = layer
	elif layer is GeoFeatureLayer:
		geo_layers["features"][layer.get_file_info()["name"]] = layer
	else:
		logger.error("Added an invalid geolayer")
		return
	
	recalculate_center()
	new_geo_layer.emit(layer)


func get_geo_layer_by_name(layer_name: String):
	if geo_layers["rasters"].has(layer_name):
		return geo_layers["rasters"][layer_name]
	elif geo_layers["features"].has(layer_name):
		return geo_layers["features"][layer_name]
	# Try and use fallback if geo layer was not loaded

	logger.warn("No layer with name %s could be found" % [layer_name])


func remove_layer_composition(layer_composition_name: String):
	if layer_compositions[layer_composition_name].is_scored:
		emit_signal("removed_scored_layer_composition", layer_composition_name)
	if is_layer_composition_rendered(layer_compositions[layer_composition_name]):
		emit_signal("removed_rendered_layer_composition", layer_composition_name, layer_compositions[layer_composition_name].render_info)
	
	emit_signal("removed_layer_composition", layer_composition_name)
	
	layer_compositions.erase(layer_composition_name)


func is_layer_composition_rendered(layer_composition: LayerComposition):
	return layer_composition.render_info != null


# Return the middle of all layers for initial loading
# FIXME: also include GeoFeatureLayers  
func recalculate_center():
	if "START" in geo_layers["features"]:
		current_center = geo_layers["features"]["START"].get_all_features()[0].get_vector3()
		current_center.z = -current_center.z
	else:
		var center_avg := Vector3.ZERO
		var count := 0
		for geolayer in geo_layers["rasters"].values():
			if geolayer is GeoRasterLayer:
				center_avg += geolayer.get_center()
				count += 1
		
		current_center = center_avg / count
