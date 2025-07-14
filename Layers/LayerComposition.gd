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

var render_info
var ui_info = UIInfo.new()

const RENDER_INFOS := {
	"Basic Terrain": BasicTerrainRenderInfo,
	"Realistic Terrain": RealisticTerrainRenderInfo,
	"Vegetation": VegetationRenderInfo,
	"Vector Vegetation": VectorVegetationRenderInfo,
	"Object": ObjectRenderInfo,
	"Wind Turbine": WindTurbineRenderInfo,
	"PolygonObject": PolygonObjectInfo,
	"Building": BuildingRenderInfo,
	"Road Network": RoadNetworkRenderInfo,
	"Connected Object": ConnectedObjectInfo,
	"Repeating Object": RepeatingObjectInfo,
	"Line Object": LineObjectInfo,
}


signal visibility_changed(visible)
signal layer_changed
signal refresh_view


# Implemented by child classes
func is_valid():
	return true


# Implemented by child classes
func get_center():
	pass


class UIInfo:
	var name_attribute


# RenderInfo data classes
class RenderInfo extends RefCounted:
	var renderer = null
	var renderer_instance: Node3D
	var icon = preload("res://Resources/Icons/ModernLandscapeLab/file.svg")
	
	func get_geolayers() -> Array:
		return []
	
	func get_described_geolayers() -> Dictionary:
		return {}
	
	func is_valid() -> bool:
		return true
	
	func get_class_name() -> String: return ""

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
	
	func _init():
		renderer = preload("res://Layers/Renderers/Terrain/BasicTerrainRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/raster.svg")
	
	func get_geolayers():
		return [height_layer, texture_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Texture": texture_layer}
	
	func is_valid():
		return height_layer != null and (is_color_shaded or texture_layer != null)
	
	func get_class_name() -> String: return "Basic Terrain"

class RealisticTerrainRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var surface_height_layer: GeoRasterLayer
	var texture_layer: GeoRasterLayer
	var landuse_layer: GeoRasterLayer
	var water_color: Dictionary
	
	func _init():
		renderer = preload("res://Layers/Renderers/Terrain/RealisticTerrainRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers():
		return [height_layer, surface_height_layer, texture_layer, landuse_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Surface height": surface_height_layer,
				"Texture": texture_layer, "Landuse": landuse_layer}
	
	func is_valid():
		return height_layer and surface_height_layer and texture_layer and landuse_layer
	
	func get_class_name() -> String: return "Realistic Terrain"

class RoadNetworkRenderInfo extends RenderInfo:
	var road_roads: GeoFeatureLayer
	var road_intersections: GeoFeatureLayer
	var height_layer: GeoRasterLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/Path/RoadNetworkRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/raster.svg")
	
	func get_geolayers():
		return [road_roads, road_intersections]
	
	func get_described_geolayers() -> Dictionary:
		return {"road_roads": road_roads, "road_intersections": road_intersections}
	
	func is_valid():
		return road_roads and road_intersections
	
	func get_class_name() -> String: return "RoadNetwork"

class VegetationRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var landuse_layer: GeoRasterLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/RasterVegetation/RasterVegetationRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/grass.svg")
	
	func get_geolayers():
		return [height_layer, landuse_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Landuse": landuse_layer}
	
	func is_valid():
		return height_layer != null and landuse_layer != null
	
	func get_class_name() -> String: return "Vegetation"

class VectorVegetationRenderInfo extends RenderInfo:
	var height_layer: GeoRasterLayer
	var plant_layer: GeoFeatureLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/VectorVegetation/VectorVegetationRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/grass.svg")
	
	func get_geolayers():
		return [height_layer, plant_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Height": height_layer, "Plants": plant_layer}
	
	func is_valid():
		return height_layer != null and plant_layer != null
	
	func get_class_name() -> String: return "VectorVegetation"

class ParticlesRenderInfo extends RenderInfo:
	pass

class ObjectRenderInfo extends RenderInfo:
	# The geodata-key-attribute that determines which connector/connection to use
	var selector_attribute_name: String
	# Either objects or meshes have to be set 
	# - objects define scenes
	# - meshes define *.tres and can be handled as multimeshinstance
	var objects: Dictionary :
		set(new_objects):
			objects = new_objects
			renderer = preload("res://Layers/Renderers/Objects/ObjectRenderer.tscn")
	var meshes: Dictionary : 
		set(new_meshes):
			meshes = new_meshes
			renderer = preload("res://Layers/Renderers/Objects/MultiMeshObjectRenderer.tscn")
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	var radius: float = 20000
	
	# For multimesh rendering
	var chunk_size: float = 1000.0
	var extent: int = 5
	var randomize: bool = false
	
	func _init():
		renderer = preload("res://Layers/Renderers/Objects/ObjectRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null
	
	func get_class_name() -> String: return "Object"

class WindTurbineRenderInfo extends ObjectRenderInfo:
	var height_attribute_name: String
	var diameter_attribute_name: String
	
	func _init():
		super._init()
		radius = 40000  # Higher detault radius since they're large
	
	func get_class_name() -> String: return "Wind Turbine"

class BuildingRenderInfo extends RenderInfo:
	var height_stdev_attribute_name: String
	var slope_attribute_name: String
	var red_attribute_name: String
	var green_attribute_name: String
	var blue_attribute_name: String
	var height_attribute_name: String
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	var addon_layers: Dictionary
	var addon_objects: Dictionary
	
	func _init():
		renderer = preload("res://Layers/Renderers/Building/BuildingRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null
	
	func get_class_name() -> String: return "Building"

class ConnectedObjectInfo extends RenderInfo:
	# The geodata-key-attribute that determines which connector/connection to use
	var selector_attribute_name: String
	# The specified connectors/connection attributes
	# e.g. "minor-power-line": "LowVoltage.tscn", "power-line": "HighVoltage.tscn"
	var connectors: Dictionary
	var connections: Dictionary
	# Should nothing be specified, take the fallbacks
	var fallback_connector: String
	var fallback_connection: String
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/ConnectedObjects/ConnectedObjectRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null
	
	func get_class_name() -> String: return "Connected Object"


class RepeatingObjectInfo extends RenderInfo:
	var width: float
	var radius := 1000.0
	var height_gradient := false
	var sample_height_at_center := true
	var random_angle: bool
	var base_rotation := 0.0
	var selector_attribute_name: String
	var meshes: Dictionary
	var attributes_to_mesh_settings: Array

	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/RepeatingObject/RepeatingObjectRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers():
		return [ground_height_layer, geo_feature_layer]
	
	func get_described_geolayers() -> Dictionary:
		return {"Ground-height": ground_height_layer, "Features": geo_feature_layer}
	
	func is_valid():
		return geo_feature_layer != null && ground_height_layer != null
	
	func get_class_name() -> String: return "Repeating Object"


class LineObjectInfo extends RenderInfo:
	var radius := 1000.0
	
	var selector_attribute_name: String
	var meshes: Dictionary
	var attributes_to_mesh_settings: Array
	
	var ground_height_layer: GeoRasterLayer
	var geo_feature_layer: GeoFeatureLayer
	
	func _init():
		renderer = preload("res://Layers/Renderers/LineObject/LineObjectRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")


class PolygonObjectInfo extends RenderInfo:
	var ground_height_layer: GeoRasterLayer
	var polygon_layer: GeoFeatureLayer
	# "virtual" layer which serves solely for using gdal features
	var geo_feature_layer: GeoFeatureLayer
	var object: String
	
	var spacing_x := -1.0
	var spacing_x_attribute: String
	
	var spacing_y := -1.0
	var spacing_y_attribute: String
	
	var amount: int
	var amount_attribute: String
	
	var individual_rotation := 0.0
	var group_rotation := 0.0
	
	func _init():
		renderer = preload("res://Layers/Renderers/PolygonObject/PolygonObjectRenderer.tscn")
		icon = preload("res://Resources/Icons/ModernLandscapeLab/vector.svg")
	
	func get_geolayers() -> Array:
		return [polygon_layer, geo_feature_layer]
	
	func get_class_name() -> String: return "Polygon Object"
