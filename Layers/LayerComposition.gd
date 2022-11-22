extends Resource
class_name LayerComposition


#
# Does caching and some logic, is the basic resource for all other scenes that work with layers
# 

var is_scored: bool = false
var is_visible: bool = true :
	get:
		return is_visible
	set(visible):
		is_visible = visible
		emit_signal("visibility_changed", is_visible)

var name: String = "Not set"

var fields: Dictionary = {}

var color_tag: Color = Color.TRANSPARENT

# NOTE: these RenderTypes have to be synchronous with the LL_render_types table in the geopackage except for NONE
enum RenderType {
	NONE,
	BASIC_TERRAIN,
	REALISTIC_TERRAIN,
	PARTICLES,
	OBJECT,
	PATH,
	CONNECTED_OBJECT,
	POLYGON,
	VEGETATION,
	TWODIMENSIONAL,
	POLYGON_OBJECT
}
var render_type = RenderType.NONE
var render_info
var ui_info = UIInfo.new()


signal visibility_changed(visible)
signal layer_changed
signal refresh_view


func is_valid():
	return render_type == RenderType.NONE or (render_info and render_info.is_valid())


# Implemented by child classes
func get_path():
	pass


# Implemented by child classes
func get_name():
	pass


# Implemented by child classes
func get_center():
	pass


class UIInfo:
	var name_attribute


# RenderInfo data classes
class RenderInfo:
	var lod = false
	
	func get_geolayers() -> Array:
		return []
	
	func get_described_geolayers() -> Dictionary:
		return {}
	
	func is_valid() -> bool:
		return true

class BasicTerrainRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var texture_layer: GeoRasterLayer
	# Data shading
	var is_color_shaded: bool
	var max_color: Color
	var min_color: Color
	var max_value: float
	var min_value: float
	var alpha: float
	
	func get_geolayers():
		return [height_layer, texture_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Texture": texture_layer}
	
	func is_valid():
		return height_layer != null and (is_color_shaded or texture_layer != null)

class RealisticTerrainRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var surface_height_layer: GeoRasterLayer
	var texture_layer: GeoRasterLayer
	var landuse_layer: GeoRasterLayer
	
	func get_geolayers():
		return [height_layer, surface_height_layer, texture_layer, landuse_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Surface height": surface_height_layer,
				"Texture": texture_layer, "Landuse": landuse_layer}
	
	func is_valid():
		return height_layer and surface_height_layer and texture_layer and landuse_layer

class VegetationRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var landuse_layer: GeoRasterLayer
	
	func get_geolayers():
		return [height_layer, landuse_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Landuse": landuse_layer}
	
	func is_valid():
		return height_layer != null and landuse_layer != null 

class ParticlesRenderInfo extends RenderInfo:
	pass

class ObjectRenderInfo extends RenderInfo:
	var object: PackedScene
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null

class WindTurbineRenderInfo extends ObjectRenderInfo:
	var height_attribute_name
	var diameter_attribute_name

class PolygonRenderInfo extends RenderInfo:
	var height_attribute_name
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null

class BuildingRenderInfo extends PolygonRenderInfo:
	var height_stdev_attribute_name
	var slope_attribute_name
	var red_attribute_name
	var green_attribute_name
	var blue_attribute_name

class PathRenderInfo extends RenderInfo:
	var line_visualization: PackedScene
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null

class ConnectedObjectInfo extends RenderInfo:
	# The geodata-key-attribute that determines which connector/connection to use
	var selector_attribute_name: String
	# The specified connectors/connection attributes
	# e.g. "minor-power-line": "LowVoltage.tscn", "power-line": "HighVoltage.tscn"
	var connectors = {}
	var connections = {}
	# Should nothing be specified, take the fallbacks
	var fallback_connector: PackedScene
	var fallback_connection: PackedScene
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null

class TwoDimensionalInfo extends RenderInfo: 
	var texture_layer: GeoRasterLayer
	
	func get_geolayers() -> Array:
		return [texture_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Texture": texture_layer}
	
	func is_valid() -> bool:
		return texture_layer.is_valid()

class PolygonObjectInfo extends RenderInfo:
	var ground_height_layer: GeoRasterLayer
	var polygon_layer: GeoFeatureLayer
	# "virtual" layer which serves solely for using gdal features
	var object_layer: GeoFeatureLayer
	var object: PackedScene
	var individual_rotation: float
	var group_rotation: float
	
	func get_geolayers() -> Array:
		return [polygon_layer, object_layer]
