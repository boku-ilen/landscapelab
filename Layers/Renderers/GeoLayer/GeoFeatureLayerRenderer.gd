extends GeoLayerRenderer


@export var radius := 100000.0
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
	var l = feature
	return Line2D.new()

var polygon_func = func(feature):
	var p = feature
	return MeshInstance2D.new()

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


func apply_new_data():
	if current_features:
		var create_func = func_dict[current_features[0].get_class()]
		
		for feature in current_features:
			add_child(create_func.call(feature))


func apply_zoom(zoom):
	for child in get_children():
		child.scale = Vector2.ONE / zoom


func get_debug_info() -> String:
	return "GeoRasterLayer."
