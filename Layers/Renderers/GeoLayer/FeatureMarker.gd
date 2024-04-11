extends Sprite2D


var feature
var layer: GeoFeatureLayer

signal popup_clicked


# Called when the node enters the scene tree for the first time.
func _ready():
	$Area2D.input_event.connect(on_input_event)
	$UI/GameObjectConfiguration.attribute_changed.connect(_on_attribute_changed)
	$UI/GameObjectConfiguration.opened.connect(_on_config_opened)
	$UI/GameObjectConfiguration.closed.connect(_on_config_closed)
	$UI/GameObjectConfiguration.delete.connect(_on_delete_pressed)


func _on_attribute_changed(reference, option_name, value):
	if option_name == "cluster_size":
		reference.change_cluster_size(value)
	else:
		reference.set(option_name, value)


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
	
	if "cluster_size" in go.collection:
		$UI/GameObjectConfiguration.add_configuration_option(
			"cluster_size", 
			go, 
			go.collection.min_cluster_size, 
			go.collection.max_cluster_size)
	
	for attribute: GameObjectAttribute in go.collection.attributes.values():
		if attribute.allow_change:
			$UI/GameObjectConfiguration.add_configuration_option(
				attribute.name, attribute, attribute.min, attribute.max)
		else:
			$UI/GameObjectConfiguration.add_attribute_information(attribute.name, str(attribute.get_value(go)))
	
	$UI/GameObjectConfiguration.popup(Rect2(get_viewport().get_canvas_transform() * global_position, $UI/GameObjectConfiguration.size))


func on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			viewport.set_input_as_handled()
			popup()
			popup_clicked.emit()

