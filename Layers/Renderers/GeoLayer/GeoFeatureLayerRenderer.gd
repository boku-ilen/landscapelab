extends GeoLayerRenderer


@export var max_features := 10000

var geo_feature_layer: GeoFeatureLayer :
	get: return geo_feature_layer
	set(feature_layer):
		geo_feature_layer = feature_layer
		# The feature-objects have different classes
		# i.e. GeoPoint, GeoLine, GeoPolygon
		var features = feature_layer.get_all_features()
		if not features.is_empty():
			type = feature_layer.get_all_features()[0].get_class()

var type: String
var current_features: Array
var renderers: Node2D

var point_func = func(feature): 
	var p = feature.get_vector3()
	var marker = Sprite2D.new()
	marker.set_texture(load("res://Resources/Icons/ClassicLandscapeLab/dot_marker.svg"))
	marker.set_position(Vector2(p.x, p.z) + Vector2(-center.x, center.y))
	marker.set_scale(Vector2.ONE / zoom)
	return marker

var line_func = func(feature):
	var curve: Curve3D = feature.get_curve3d()
	var line := Line2D.new()
	line.set_default_color(Color.CRIMSON)
	line.points = Array(curve.tessellate()).map(
		func(vec3): 
			return Vector2(vec3.x, vec3.z) + Vector2(-center.x, center.y))
	line.width = 1 / zoom.x
	return line

var polygon_func = func(feature): 
	var p = feature.get_outer_vertices()
	var polygon = Polygon2D.new()
	polygon.set_polygon(Array(p).map(func(vec2): return vec2 - center))
	polygon.set_color(Color.CYAN)
	polygon.scale.y = -1
	return polygon

var func_dict = {
	"GeoPoint": point_func,
	"GeoLine": line_func,
	"GeoPolygon": polygon_func
}


func load_new_data():
	var position_x = center[0]
	var position_y = center[1]
	
	if geo_feature_layer:
		current_features = geo_feature_layer.get_features_near_position(
			float(position_x),
			float(position_y),
			float(radius),
			max_features
		)
		
		# Create a scene-chunk and set it deferred so there are no thread unsafeties
		var renderers_thread_safe = Node2D.new()
		for feature in current_features:
			var visualizer = func_dict[type].call(feature)
			renderers_thread_safe.add_child(visualizer)
	
		call_deferred(set_renderers(renderers_thread_safe))


func set_renderers(visualizers: Node2D):
	renderers = visualizers


func apply_new_data():
	# First remove all previous features
	for feature_vis in get_children():
		feature_vis.queue_free()
	
	add_child(renderers)


func apply_zoom():
	if type == "GeoPoint":
		for child in get_children():
			child.scale = Vector2.ONE / zoom
	elif type == "GeoLine":
		for child in get_children():
			child.width = 1 / zoom.x


func get_debug_info() -> String:
	return "GeoRasterLayer."
