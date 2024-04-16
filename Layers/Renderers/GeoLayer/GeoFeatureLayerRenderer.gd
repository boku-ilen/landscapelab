extends GeoLayerRenderer


@export var max_features := 10000

var geo_feature_layer: GeoFeatureLayer
var current_features: Array
var renderers: Node2D

var newest_feature = null

var icon
var icon_scale = 0.1
var min_zoom = 0.0

signal popup_clicked

var point_func = func(feature: GeoPoint): 
	var p = feature.get_vector3()
	var marker = preload("res://Layers/Renderers/GeoLayer/FeatureMarker.tscn").instantiate()
	marker.set_texture(icon)
	marker.set_position(global_vector3_to_local_vector2(p))
	marker.set_scale(Vector2.ONE * icon_scale / zoom)
	marker.feature = feature
	marker.layer = geo_feature_layer
	marker.popup_clicked.connect(func(): popup_clicked.emit())
	return marker

var line_func = func(feature: GeoLine):
	var curve: Curve3D = feature.get_curve3d()
	var line := Line2D.new()
	line.set_default_color(Color.CRIMSON)
	line.points = Array(curve.tessellate()).map(
		func(vec3): return global_vector3_to_local_vector2(vec3))
	line.width = 1 / zoom.x
	return line

var polygon_func = func(feature: GeoPolygon): 
	var p = feature.get_outer_vertices()
	var polygon = Polygon2D.new()
	polygon.set_polygon(Array(p).map(
		func(vec2): return global_vector2_to_local_vector2(vec2)))
	polygon.set_color(Color.CYAN)
	polygon.scale.y = -1
	return polygon

var func_dict = {
	"GeoPoint": point_func,
	"GeoLine": line_func,
	"GeoPolygon": polygon_func
}


func load_new_data(is_threaded := true):
	var load_position = get_center_global()
	
	if geo_feature_layer:
		current_features = geo_feature_layer.get_features_near_position(
			load_position.x,
			load_position.y,
			float(radius),
			max_features
		)
		
		
		# Create a scene-chunk and set it deferred so there are no thread unsafeties
		var renderers_thread_safe = Node2D.new()
		for feature in current_features:
			var visualizer = func_dict[feature.get_class()].call(feature)
			renderers_thread_safe.add_child(visualizer)
		
		if is_threaded:
			call_deferred("set_renderers", renderers_thread_safe)
			return
		
		renderers = renderers_thread_safe


func set_renderers(visualizers: Node2D):
	renderers = visualizers


func apply_new_data():
	print(zoom.x)
	if zoom.x > min_zoom:
		visible = true
	else:
		visible = false
	
	# First remove all previous features
	for feature_vis in get_children():
		feature_vis.queue_free()
	
	add_child(renderers)
	
	if newest_feature:
		for visualizer in renderers.get_children():
			if visualizer.feature.get_vector3() == newest_feature.get_vector3():
				visualizer.popup()
		newest_feature = null


# Currently all features are always deleted and loaded new
# this might be necessary when persisting features
func apply_zoom():
	if geo_feature_layer.get_all_features()[0] is GeoPoint:
		for child in get_children():
			child.scale = Vector2.ONE / zoom
	elif geo_feature_layer.get_all_features()[0] is GeoLine:
		for child in get_children():
			child.width = 1 / zoom.x


func get_debug_info() -> String:
	return "GeoRasterLayer."


func refresh():
	load_new_data(false)
	apply_new_data()
