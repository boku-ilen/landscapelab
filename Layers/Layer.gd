extends Resource
class_name Layer


#
# Does caching and some logic, is the basic resource for all other scenes that work with layers
# 

var is_scored: bool = false
var is_visible: bool = true

var name: String

var fields: Dictionary = {}

enum RenderType {
	NONE,
	TERRAIN,
	PARTICLES,
	OBJECT,
	PATH,
	CONNECTED_OBJECT,
	POLYGON
}
var render_type = RenderType.NONE
var render_info

# RenderInfo data classes
class RenderInfo:
	var lod = false

class TerrainRenderInfo extends RenderInfo:
	var height_layer: Layer
	var texture_layer: Layer

class ParticlesRenderInfo extends RenderInfo:
	pass

class ObjectRenderInfo extends RenderInfo:
	var object: PackedScene
