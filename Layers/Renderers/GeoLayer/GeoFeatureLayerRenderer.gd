extends GeoLayerRenderer


@export var max_features := 10000

var geo_feature_layer: GeoFeatureLayer
var current_features: Array
var renderers: Node2D

var newest_feature = null

signal popup_clicked


func parse_attribute_expression(feature, formula):
	# Insert attribute values into formula
	var formated_string = formula
	
	while formated_string.find("$") >= 0:
		var begin_index = formated_string.find("$", 0)
		var length = formated_string.find("$", begin_index + 1) - begin_index
		var slice = formated_string.substr(begin_index + 1, length - 1)
		
		var value = feature.get_attribute(slice)
		
		formated_string = formated_string.left(begin_index) + str(value) + formated_string.right(-(begin_index + length + 1))
	
	var expression = Expression.new()
	expression.parse(formated_string)
	var result = expression.execute()
	
	if not result: result = 0.0
	
	return result

var point_func = func(feature: GeoPoint): 
	#if layer_definition.render_info.marker != null:
	#	return layer_definition.render_info.marker
	
	var marker = preload("res://Layers/Renderers/GeoLayer/FeatureMarker.tscn").instantiate()
	
	set_feature_icon(feature, marker)
	
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


# FIXME: There is a lot of logic which really should not be handled here (i.e. deserialization of a config)
func set_feature_icon(feature, marker):
	var config = layer_definition.render_info.config
	if "attribute_icon" in config:
		var attribute_name = config["attribute_icon"]["attribute"]
		var go = GameSystem.get_game_object_for_geo_feature(feature)
		var attribute_value = go.get_attribute(attribute_name)
		
		for threshold_value in config["attribute_icon"]["thresholds"].keys():
			if attribute_value <= str_to_var(threshold_value):
				marker.set_texture(load(config["attribute_icon"]["thresholds"][threshold_value]))
				marker.set_scale(Vector2.ONE * config["icon_scale"] / zoom)
				break
	elif "icon_near" in config and zoom.x >= config["icon_near_switch_zoom"]:
		marker.set_texture(load(config["icon_near"]))
		
		if "icon_near_scale_formula" in config:
			marker.set_scale(Vector2.ONE * parse_attribute_expression(feature, config["icon_near_scale_formula"]))
		else:
			marker.set_scale(Vector2.ONE * config["icon_near_scale"])
	else:
		marker.set_texture(load(config["icon"]))
		marker.set_scale(Vector2.ONE * config["icon_scale"] / zoom)
	
	var p = feature.get_vector3()
	marker.set_position(global_vector3_to_local_vector2(p))
	marker.feature = feature
	marker.layer = geo_feature_layer
	marker.popup_clicked.connect(func(): popup_clicked.emit())


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
		var new_renderers = Node2D.new()
		for feature in current_features:
			var visualizer = func_dict[feature.get_class()].call(feature)
			new_renderers.add_child(visualizer)
		
		renderers = new_renderers


func apply_new_data():
	if (not layer_definition.render_info.config) or (not "min_zoom" in layer_definition.render_info.config) or (zoom.x > layer_definition.render_info.config["min_zoom"]):
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
