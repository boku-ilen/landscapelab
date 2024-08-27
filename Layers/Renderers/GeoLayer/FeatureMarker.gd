extends Sprite2D


@export var radius := 30.0

var feature
var layer: GeoFeatureLayer

signal popup_clicked


# Called when the node enters the scene tree for the first time.
func _ready():
	$UI/GameObjectConfiguration.attribute_changed.connect(_on_attribute_changed)
	$UI/GameObjectConfiguration.opened.connect(_on_config_opened)
	$UI/GameObjectConfiguration.closed.connect(_on_config_closed)
	$UI/GameObjectConfiguration.delete.connect(_on_delete_pressed)
	
	feature.feature_changed.connect(popup, CONNECT_DEFERRED)


func _on_attribute_changed(reference, option_name, value):
	if option_name == "Amount":
		reference.change_cluster_size(value)
	else:
		GameSystem.get_game_object_for_geo_feature(feature).set_attribute(option_name, value)


# When the pop-up is opened, disable the interaction Area2D to prevent conflicts
func _on_config_opened():
	$Area2D.process_mode = Node.PROCESS_MODE_DISABLED


func _on_config_closed():
	$Area2D.process_mode = Node.PROCESS_MODE_INHERIT


func _on_delete_pressed():
	popup_clicked.emit()
	layer.remove_feature(feature)


func popup():
	$UI/GameObjectConfiguration.clear_attributes()
	
	var go = GameSystem.get_game_object_for_geo_feature(feature)
	var attributes = go.get_attributes()
	
	if go.collection is GameObjectClusterCollection:
		$UI/GameObjectConfiguration.add_configuration_option(
			"Amount", 
			go, 
			go.collection.min_cluster_size, 
			go.collection.max_cluster_size,
			go.cluster_size)
	
	for attribute: GameObjectAttribute in go.collection.attributes.values():
		if attribute.show_in_config:
			if attribute.allow_change:
				if attribute is ClassGameObjectAttribute:
					$UI/GameObjectConfiguration.add_configuration_class_option(
						attribute.name, attribute, attribute.class_names_to_attribute_values, attribute.get_value(go)
					)
				else:
					$UI/GameObjectConfiguration.add_configuration_option(
						attribute.name, attribute, attribute.min, attribute.max, attribute.get_value(go))
			else:
				var value = attribute.get_value(go)
				if value is float: value = "%.1f" % value
				$UI/GameObjectConfiguration.add_attribute_information(attribute.name, str(value))
	
	$UI/GameObjectConfiguration.popup(Rect2(get_viewport().get_canvas_transform() * global_position, $UI/GameObjectConfiguration.size))


func _unhandled_input(event):
	if not is_visible_in_tree(): return
	
	if not GameSystem.get_game_object_for_geo_feature(feature) or not GameSystem.get_game_object_for_geo_feature(feature).collection.name in GameSystem.current_game_mode.game_object_collections.keys(): return
	
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_2d()
		var global_event_position = camera.screen_to_global(event.position)
		
		if global_event_position.distance_to(global_position) < radius / camera.zoom.x:
			get_viewport().set_input_as_handled()
			popup()
			popup_clicked.emit()
