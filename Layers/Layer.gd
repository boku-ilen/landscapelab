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
	TERRAIN,
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

# RenderInfo data classes
class RenderInfo:
	var lod = false

class TerrainRenderInfo extends RenderInfo:
	var height_layer: Layer
	var texture_layer: Layer
	var is_color_shaded: bool
	var max_color: Color
	var min_color: Color

class VegetationRenderInfo extends RenderInfo:
	var height_layer: Layer
	var landuse_layer: Layer
	var extent: float
	var density: float
	var min_plant_size: float
	var max_plant_size: float
	var mesh: Resource

class ParticlesRenderInfo extends RenderInfo:
	pass

class ObjectRenderInfo extends RenderInfo:
	var object: PackedScene
	var ground_height_layer: Layer

class PolygonRenderInfo extends RenderInfo:
	var height_attribute_name
	var ground_height_layer: Layer
