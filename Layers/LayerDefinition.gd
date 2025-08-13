extends Resource
class_name LayerDefinition


var crs_from:=3857
var name: String

# wrapper class for serialization logic
class LayerCompositionReference extends AbstractLayerSerializer.SerializationWrapper:
	var composition_name: String : 
		set(new_name):
			composition_name = new_name
			if "geo_feature_layer" in Layers.layer_compositions[composition_name].render_info:
				geo_feature_layer = Layers.layer_compositions[composition_name].render_info.geo_feature_layer
			else:
				logger.warn("A reference to %s was initialized, but no geo_feature_layer could be found" % [composition_name])
	 
	var geo_feature_layer: GeoFeatureLayer
	
	static func get_class_name():
		return "LayerCompositionReference"


class RenderInfo:
	signal z_index_changed(index)
	signal visibility_changed(visible)
	
	var layer_composition_reference := LayerCompositionReference.new() : 
		set(new_reference):
			layer_composition_reference = new_reference
			if "geo_layer" in self:
				set("geo_layer", layer_composition_reference.geo_feature_layer)
	var is_visible: bool :
		set(visible):
			is_visible = visible
			visibility_changed.emit(visible)
	var z_index: int : 
		set(index):
			z_index = index
			z_index_changed.emit(index)

	var type := TYPE.RASTER
	var no_data

class FeatureRenderInfo extends RenderInfo:
	var geo_layer: GeoFeatureLayer
	var marker: Texture
	var marker_scale: float = 0.1
	var attribute_name: String 
	var thresholds: Array
	var marker_near: Texture
	var marker_near_switch_zoom: float
	var marker_near_scale_formula: float
	var marker_near_scale: float
	var config: Dictionary # FIXME: corresponds to the func set_feature_icon(feature, marker): in GeoFeatureLayerRenderer

class RasterRenderInfo extends RenderInfo:
	var geo_layer: GeoRasterLayer
	var gradient: Gradient
	var min_val: float
	var max_val: float

class UIInfo:
	var name: String
	var icon: Texture = preload("res://Resources/Icons/ModernLandscapeLab/file.svg")
	var description: String


enum TYPE {
	RASTER,
	FEATURE
}

var ui_info: UIInfo = UIInfo.new()
var render_info: RenderInfo


func _init(_z_index=null) -> void:
	if _z_index != null:
		render_info.z_index = _z_index
		return
	
	if render_info == null:
		return
		
	if Layers.layer_definitions.is_empty():
		render_info.z_index = 0
		return
	
	if Layers.layer_definitions.size() < 2:
		render_info.z_index = Layers.layer_definitions.values()[0].z_index + 1
		return
	
	var max_z = Layers.layer_definitions.values().reduce(
		func(ld1, ld2): return ld1 if ld1.z_index > ld2.z_index else ld2).z_index
	render_info.z_index = max_z
