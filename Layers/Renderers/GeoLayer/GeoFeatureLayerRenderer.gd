extends GeoLayerRenderer
class_name GeoFeatureLayerRenderer


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


func set_feature_icon(feature, marker):
	var render_info: LayerDefinition.FeatureRenderInfo = layer_definition.render_info
	
	if "meters_per_pixel" in feature.get_attributes().keys():
		var res_x = feature.get_attribute("width")
		var res_y = feature.get_attribute("height")
		var lid = int(feature.get_attribute("lid"))
		var data = feature.get_binary_attribute("image")
		var image = Image.create_from_data(int(res_x), int(res_y), false, Image.FORMAT_R8, data)
		
		if not image:
			logger.error("Image creation failed for image of feature with ID %s" % [str(feature.get_id())])
			return
		
		var texture = ImageTexture.create_from_image(image)
		marker.set_texture(texture)
		
		# Calculate the marker scale in WebMercator units by comparing the difference between 1 
		# projected unit and 1 unprojected unit; start from x=0 for good float accuracy
		var position_orig = feature.get_vector3() * Vector3(0.0, 1.0, 1.0)
		var one_right_orig = Vector3(float(feature.get_attribute("meters_per_pixel")), position_orig.y, position_orig.z)
		
		var position_3857 = global_vector3_to_local_vector2(position_orig)
		var one_right_3857 = global_vector3_to_local_vector2(one_right_orig)
		
		var delta_3857 = (one_right_3857 - position_3857).length()
		marker.set_scale(Vector2.ONE * delta_3857)
		
		var mat = ShaderMaterial.new()
		mat.set_shader(preload("res://UI/LabTable/ColoredOverlay.gdshader"))
		
		# Set color from config, if available; otherwise calculate a distinct fallback color
		if str(lid) in layer_definition.render_info.lid_to_color:
			mat.set_shader_parameter("color", Color(layer_definition.render_info.lid_to_color[str(lid)]))
		else:
			# TODO: better default logic for this?
			mat.set_shader_parameter("color", Vector3((lid % 255), floor(lid / 255.0) * 30, 0))
		
		marker.set_material(mat)
		
		marker.z_index = 1  # FIXME: Why is this needed? The z index should be set in the layer...
		
	elif render_info.attribute_icon.attribute != "":
		var go = GameSystem.get_game_object_for_geo_feature(feature)
		var attribute_value = go.get_attribute(render_info.attribute_icon.attribute)
		
		# Default: last entry
		var last_threshold = render_info.attribute_icon.thresholds.keys().back()
		marker.set_texture(load(render_info.attribute_icon.thresholds[last_threshold]))
		marker.set_scale(Vector2.ONE * render_info.marker_scale / zoom)
		
		# Check if an earlier entry applies
		for threshold in render_info.attribute_icon.thresholds.keys():
			if attribute_value <= str_to_var(threshold):
				marker.set_texture(load(render_info.attribute_icon.thresholds[threshold]))
				marker.set_scale(Vector2.ONE * render_info.marker_scale / zoom)
				break
	else:
		marker.set_texture(layer_definition.render_info.marker)
		marker.set_scale(Vector2.ONE * layer_definition.render_info.marker_scale / zoom)

	if render_info.marker_near != null and zoom.x >= render_info.marker_near_switch_zoom:
		var near_sprite = Sprite2D.new() if not marker.has_node("IconNear") else marker.get_node("IconNear")

		near_sprite.name = "IconNear"
		near_sprite.texture = render_info.marker_near

		if render_info.marker_near_scale_formula != null:
			near_sprite.set_scale((Vector2.ONE / marker.scale) * parse_attribute_expression(feature, render_info.marker_near_scale_formula))
		else:
			near_sprite.set_scale((Vector2.ONE / marker.scale) * render_info.marker_near_scale)
		
		marker.add_child(near_sprite)
	
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
