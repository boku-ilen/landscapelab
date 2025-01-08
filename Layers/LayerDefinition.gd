extends Resource
class_name LayerDefinition

signal z_index_changed(index)
signal visibility_changed(visible)

var geo_layer: RefCounted
var crs_from:=3857
var name: String

class RenderInfo:
	var no_data

class FeatureRenderInfo extends RenderInfo:
	var marker

class RasterRenderInfo extends RenderInfo:
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

var is_visible: bool :
	set(visible):
		is_visible = visible
		visibility_changed.emit(visible)
var z_index: int : 
	set(index):
		z_index = index
		z_index_changed.emit(index)

var type := TYPE.RASTER


func _init(_geo_layer: RefCounted=GeoFeatureLayer.new(), _z_index=null) -> void:
	geo_layer = _geo_layer
	name = geo_layer.get_file_info()["name"]
	if geo_layer is GeoRasterLayer:
		render_info = RasterRenderInfo.new()
		type = TYPE.RASTER
	elif geo_layer is GeoFeatureLayer:
		render_info = FeatureRenderInfo.new()
		type = TYPE.FEATURE
	else:
		logger.error("Invalid geo layer has been passed to LayerDefinition")

	is_visible = true
	
	if _z_index == null:
		var max_z = Layers.layer_definitions.values().reduce(func(ld1: LayerDefinition, ld2): 
			return max(ld1.z_index, ld2.z_index))
		if max_z == null: max_z = -1
		
		z_index = max_z + 1
	else: 
		z_index = _z_index
