extends Node
class_name LayerDefinition

var geo_layer: RefCounted

class RenderInfo:
	var icon: Texture
	var shader: Shader
	var texture: Texture
	var color: Color

class FeatureRenderInfo extends RenderInfo:
	var marker

class RasterRenderInfo extends RenderInfo:
	var min_value: float
	var max_value: float

class UIInfo:
	var name: String
	var icon: Texture
	var description: String

enum TYPE {
	RASTER,
	FEATURE
}

var ui_info: UIInfo
var render_info: RenderInfo

var is_visible: bool
var z_index: int

var type := TYPE.RASTER


func _init(_geo_layer: RefCounted) -> void:
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
	z_index = 0
