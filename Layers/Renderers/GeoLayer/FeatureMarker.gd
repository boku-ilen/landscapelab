extends Sprite2D


var feature

signal popup_clicked


# Called when the node enters the scene tree for the first time.
func _ready():
	$Area2D.input_event.connect(on_input_event)
	$UI/GameObjectConfiguration.attribute_changed.connect(_on_attribute_changed)


func _on_attribute_changed(reference, option_name, value):
	print(reference, option_name, value)
	
	if option_name == "cluster_size":
		reference.change_cluster_size(value)
	else:
		reference.set(option_name, value)


func popup():
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
		viewport.set_input_as_handled()
		
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			popup()
			popup_clicked.emit()

