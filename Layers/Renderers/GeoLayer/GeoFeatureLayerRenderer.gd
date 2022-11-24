extends GeoLayerRenderer


@export var radius := 10000.0
@export var max_features := 1000

var geo_feature_layer: GeoFeatureLayer
var current_features: Array

var point_func = func(feature): 
	var p = feature.get_offset_vector3(-center[0], 0, -center[1])
	var marker = Sprite2D.new()
	marker.set_texture(load("res://Resources/Icons/ClassicLandscapeLab/dot_marker.svg"))
	marker.set_position(Vector2(p.x, p.z))
	return marker

var line_func = func(feature):
	var curve: Curve3D = feature.get_offset_curve3d(-center[0], 0, -center[1])
	var line := Line2D.new()
	line.set_default_color(Color.CRIMSON)
	line.points = Array(curve.tessellate()).map(func(vec3): return Vector2(vec3.x, vec3.z))
	return line

var polygon_func = func(feature):
	var p = feature.get_outer_vertices()
	var polygon = Polygon2D.new()
	polygon.set_polygon(Array(p).map(func(vec2): return vec2 - Vector2(center[0], center[1])))
	polygon.set_color(Color.CYAN)
	polygon.scale.y = -1
	return polygon

var func_dict = {
	"GeoPoint": point_func,
	"GeoLine": line_func,
	"GeoPolygon": polygon_func
}

var is_what: String

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


func apply_new_data():
	if current_features:
		is_what = current_features[0].get_class()
		var create_func = func_dict[is_what]
		
		for feature in current_features:
			var visualizer = create_func.call(feature)
			if visualizer: add_child(visualizer) 


func apply_zoom(zoom):
	if is_what == "GeoPoint":
		for child in get_children():
			child.scale = Vector2.ONE / zoom
	elif is_what == "GeoLine":
		for child in get_children():
			child.width = 1 / zoom.x


func get_debug_info() -> String:
	return "GeoRasterLayer."
