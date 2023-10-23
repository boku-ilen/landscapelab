extends PopupMenu


var geo_layer


func _ready():
	# Set meta data functions to be called when the item is pressed
	# Visibility-item
	set_item_metadata(0, 
		func(index):
			# TODO: Make some kind of MVC pattern around this whole thing
			# TODO: to properly store the state of a geolayer (e.g. visibility) 
			#set_item_checked(index, !is_item_checked(index))
			get_parent().geolayer_visibility_changed.emit(
				geo_layer.get_file_info()["name"], is_item_checked(index)))
	# Saving-item
	set_item_metadata(1, 
		func(index): if geo_layer is GeoFeatureLayer: geo_layer.save_override()) 
	
	# Call meta-data function on pressed
	index_pressed.connect(func(index): 
		get_item_metadata(index).call(index) if get_item_metadata(index) is Callable else null)


func menu_popup(rect: Rect2, layer):
	geo_layer = layer
	popup(rect)
