extends Resource
class_name Layer


#
# Does caching and some logic, is the basic resource for all other scenes that work with layers
# 

var is_scored: bool = false
var is_visible: bool = true setget set_visible

var name: String = "Not set"

var fields: Dictionary = {}

var color_tag: Color = Color.transparent

enum RenderType {
	NONE,
	BASIC_TERRAIN,
	REALISTIC_TERRAIN,
	PARTICLES,
	OBJECT,
	PATH,
	CONNECTED_OBJECT,
	POLYGON,
	VEGETATION
}
var render_type = RenderType.NONE
var render_info


signal visibility_changed(visible)
signal layer_changed


func set_visible(visible: bool):
	is_visible = visible
	emit_signal("visibility_changed", is_visible)


func is_valid():
	return render_type == RenderType.NONE or (render_info and render_info.is_valid())


# RenderInfo data classes
class RenderInfo:
	var lod = false
	
	func is_valid():
		return true

class BasicTerrainRenderInfo extends RenderInfo:
	var height_layer: Layer
	var texture_layer: Layer
	var is_color_shaded: bool
	var max_color: Color
	var min_color: Color
	var alpha: float
	
	func is_valid():
		return height_layer != null and (is_color_shaded or texture_layer != null)

class RealisticTerrainRenderInfo extends RenderInfo:
	var height_layer: Layer
	var surface_height_layer: Layer
	var texture_layer: Layer
	var landuse_layer: Layer
	
	func is_valid():
		return height_layer and surface_height_layer and texture_layer and landuse_layer

class VegetationRenderInfo extends RenderInfo:
	var height_layer: Layer
	var landuse_layer: Layer
	var extent: float
	var density: float
	var min_plant_size: float
	var max_plant_size: float
	var mesh: Resource
	
	func is_valid():
		return height_layer != null and landuse_layer != null 

class ParticlesRenderInfo extends RenderInfo:
	pass

class ObjectRenderInfo extends RenderInfo:
	var object: PackedScene
	var ground_height_layer: Layer
	
	func is_valid():
		return ground_height_layer != null

class PolygonRenderInfo extends RenderInfo:
	var height_attribute_name
	var ground_height_layer: Layer
	
	func is_valid():
		return ground_height_layer != null

class BuildingRenderInfo extends PolygonRenderInfo:
	var slope_attribute_name
	var red_attribute_name
	var green_attribute_name
	var blue_attribute_name

class PathRenderInfo extends RenderInfo:
	var line_visualization: PackedScene
	var ground_height_layer: Layer
	
	func is_valid():
		return ground_height_layer != null

class ConnectedObjectInfo extends RenderInfo:
	var connection_visualization: PackedScene
	var object: PackedScene
	var ground_height_layer: Layer
	
	func is_valid():
		return ground_height_layer != null
