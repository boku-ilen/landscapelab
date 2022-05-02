extends SpecificLayerUI


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.PolygonRenderInfo.new()
	
	var polygon_layer = $RightBox/PolygonChooser.get_geo_layer(false)
	var height_layer = $RightBox/GroundHeightChooser.get_geo_layer(true)

	if !validate(polygon_layer) or !validate(height_layer):
		print_warning("Polygon- or height-layer is invalid!")
		return

	layer.geo_feature_layer = polygon_layer#.clone()
	layer.render_info.ground_height_layer = height_layer.clone()
	layer.render_info.height_attribute_name = $RightBox/HeightAttributeText.text


func init_specific_layer_info(layer):
	$RightBox/GroundHeightChooser.init_from_layer(
		layer.render_info.ground_height_layer)
	$RightBox/PolygonChooser.init_from_layer(
		layer.geo_feature_layer)
