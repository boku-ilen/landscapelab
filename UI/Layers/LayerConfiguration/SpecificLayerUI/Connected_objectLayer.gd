extends SpecificLayerUI


var co_attribute_config = load("res://UI/Layers/LayerConfiguration/Misc/ConnectedObjectAttribute.tscn")


func _ready():
	$AdditionalAttribute/AddTribute.connect("pressed", self, "_on_additional_pressed")
	$Split/RightBox/COChooser.connect("new_layer_selected", $Split/RightBox/SelectorAttrDD, "set_feature_layer")
	
	emit_signal("resized")


func _on_additional_pressed():
	$AdditionalAttribute.add_child(co_attribute_config.instance())


func assign_specific_layer_info(layer: Layer):
	if layer.render_info == null:
		layer.render_info = Layer.ConnectedObjectInfo.new()
	
	var co_layer = $Split/RightBox/COChooser.get_geo_layer(false)
	var height_layer = $Split/RightBox/GroundHeightChooser.get_geo_layer(true)

	if !validate(co_layer) or !validate(height_layer):
		print_warning("Polygon- or height-layer is invalid!")
		return

	layer.geo_feature_layer = co_layer
	layer.render_info.ground_height_layer = height_layer.clone()
	layer.render_info.selector_attribute_name = \
		$Split/RightBox/SelectorAttrDD.get_item_text($Split/RightBox/SelectorAttrDD.get_selected_id())
		
	layer.render_info.fallback_connector = load($Split/RightBox/ConnectorChooser/FileName.text)
	layer.render_info.fallback_connection = load($Split/RightBox/ConnectionChooser/FileName.text)
	
	for child in $AdditionalAttribute.get_children():
		if not child.has_method("get_value"): continue
		
		var f = File.new()
		if f.file_exists(child.get_connector()) and child.get_connector().get_extension() == "tscn":
			layer.render_info.connectors[child.get_value()] = load(child.get_connector())
		if f.file_exists(child.get_connection()) and child.get_connection().get_extension() == "tscn":
			layer.render_info.connections[child.get_value()] = load(child.get_connection())


func init_specific_layer_info(layer):
	$Split/RightBox/GroundHeightChooser.init_from_layer(
		layer.render_info.ground_height_layer)
	$Split/RightBox/COChooser.init_from_layer(
		layer.geo_feature_layer)
	
	$Split/RightBox/SelectorAttrDD.set_feature_layer(layer)
	$Split/RightBox/SelectorAttrDD.set_selected_by_text(layer.render_info.selector_attribute_name)
	
	$Split/RightBox/ConnectorChooser/FileName.text = layer.render_info.fallback_connector.get_path()
	$Split/RightBox/ConnectionChooser/FileName.text = layer.render_info.fallback_connection.get_path()
	
	var additonal_attributes = $AdditionalAttribute
	for value in layer.render_info.connectors:
		var conf = co_attribute_config.instance()
		conf.name = value
		conf.set_value(value)
		conf.set_connector(layer.render_info.connectors[value].get_path())
		
		# if the connections also contain an entry with this value add it while at it
		if value in layer.render_info.connections:
			conf.set_connection(layer.render_info.connections[value].get_path())
		
		additonal_attributes.add_child(conf)
	
	for value in layer.render_info.connections:
		# since we added before we can skip here, if a child with this name exists
		var names = []
		for child in additonal_attributes.get_children(): 
			if child.has_method("get_value"): names.append(child.get_value())
		if value in names: continue
		
		var conf = co_attribute_config.instance()
		conf.name = value
		conf.set_value(value)
		conf.set_connection(layer.render_info.connections[value].get_path())
		
		additonal_attributes.add_child(conf)
