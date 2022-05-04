extends SpecificLayerUI


func _ready():
	$RightBox/PolygonChooser.connect("new_layer_selected", $RightBox/HeightAttrDD, "set_feature_layer")
	for child in $RightBox/BuildingInfo.get_children():
		$RightBox/PolygonChooser.connect("new_layer_selected", child, "set_feature_layer")
	
	$RightBox/BuildingCheckBox.connect("toggled", self, "_set_building_info_visible")


func _set_building_info_visible(toggled: bool):
	$LeftBox/BuildingInfo.visible = toggled
	$RightBox/BuildingInfo.visible = toggled


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		if not $RightBox/BuildingCheckBox.pressed:
			layer.render_info = Layer.PolygonRenderInfo.new()
		else:
			layer.render_info = Layer.BuildingRenderInfo.new()
			layer.render_info.height_stdev_attribute_name = \
				$RightBox/BuildingInfo/HeightStdAttrDD.get_item_text($RightBox/BuildingInfo/HeightStdAttrDD.get_selected_id())
			layer.render_info.slope_attribute_name = \
				$RightBox/BuildingInfo/SlopeAttrDD.get_item_text($RightBox/BuildingInfo/SlopeAttrDD.get_selected_id())
			layer.render_info.red_attribute_name = \
				$RightBox/BuildingInfo/RedAttrDD.get_item_text($RightBox/BuildingInfo/RedAttrDD.get_selected_id())
			layer.render_info.green_attribute_name = \
				$RightBox/BuildingInfo/GreenAttrDD.get_item_text($RightBox/BuildingInfo/GreenAttrDD.get_selected_id())
			layer.render_info.blue_attribute_name = \
				$RightBox/BuildingInfo/BlueAttrDD.get_item_text($RightBox/BuildingInfo/BlueAttrDD.get_selected_id())
	
	var polygon_layer = $RightBox/PolygonChooser.get_geo_layer(false)
	var height_layer = $RightBox/GroundHeightChooser.get_geo_layer(true)

	if !validate(polygon_layer) or !validate(height_layer):
		print_warning("Polygon- or height-layer is invalid!")
		return

	layer.geo_feature_layer = polygon_layer
	layer.render_info.ground_height_layer = height_layer.clone()
	layer.render_info.height_attribute_name = \
		$RightBox/HeightAttrDD.get_item_text($RightBox/HeightAttrDD.get_selected_id())


func init_specific_layer_info(layer):
	$RightBox/GroundHeightChooser.init_from_layer(
		layer.render_info.ground_height_layer)
	$RightBox/PolygonChooser.init_from_layer(
		layer.geo_feature_layer)
	
	$RightBox/HeightAttrDD.set_feature_layer(layer)
	$RightBox/HeightAttrDD.set_selected_by_text(layer.render_info.height_attribute_name)
	
	$RightBox/BuildingCheckBox.set_pressed(layer.render_info is Layer.BuildingRenderInfo)
	
	if $RightBox/BuildingCheckBox.pressed:
		_set_building_info_visible(true)
		for child in $RightBox/BuildingInfo.get_children():
			child.set_feature_layer(layer.geo_feature_layer)
			
		$RightBox/BuildingInfo/HeightStdAttrDD.set_selected_by_text(layer.render_info.height_stdev_attribute_name)
		$RightBox/BuildingInfo/SlopeAttrDD.set_selected_by_text(layer.render_info.slope_attribute_name)
		$RightBox/BuildingInfo/RedAttrDD.set_selected_by_text(layer.render_info.red_attribute_name)
		$RightBox/BuildingInfo/GreenAttrDD.set_selected_by_text(layer.render_info.green_attribute_name)
		$RightBox/BuildingInfo/BlueAttrDD.set_selected_by_text(layer.render_info.blue_attribute_name)
