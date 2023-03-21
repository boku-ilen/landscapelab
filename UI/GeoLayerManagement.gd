extends HBoxContainer


@export var action_handler_paths: Array[NodePath]
@export_node_path("ItemList") var geo_layer_list_path
@onready var geo_layer_list: ItemList = get_node(geo_layer_list_path)


func _ready():
	geo_layer_list.item_selected.connect(
		func(idx): _on_geo_layer_selected(geo_layer_list.get_item_metadata(idx))
	)
	$GeoFeatureLayerManagement.set_buttons_active(false)
	for handler in action_handler_paths.map(func(path): return get_node(path)):
		var action_handler: ActionHandler = handler
		$GeoFeatureLayerManagement/Add.toggled.connect(func(toggled: bool): 
				var _class_name = $GeoFeatureLayerManagement.geo_feature_layer.create_feature().get_class()
				if toggled:
					action_handler.set_current_action(
						$GeoFeatureLayerManagement.add_actions[
							_class_name
							# FIXME: add a get_feature_type in geodot
							#$GeoFeatureLayerManagement.geo_feature_layer.get_feature_type()
						])
				else: action_handler.stop_current_action())


func _on_geo_layer_selected(geo_layer):
	if geo_layer is GeoFeatureLayer:
		$GeoFeatureLayerManagement.geo_feature_layer = geo_layer
		$GeoFeatureLayerManagement.set_buttons_active(true)
#		$GeoRasterLayerManagement.geo_raster_layer = null
#		$GeoRasterLayerManagement.set_buttons_active(false)
	elif geo_layer is GeoRasterLayer:
#		$GeoRasterLayerManagement.geo_raster_layer = geo_layer
#		$GeoRasterLayerManagement.set_buttons_active(true)
		$GeoFeatureLayerManagement.geo_feature_layer = null
		$GeoFeatureLayerManagement.set_buttons_active(false)
