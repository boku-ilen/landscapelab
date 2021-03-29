extends OptionButton


func _ready():
	# Add all density classes
	var item_id = 0
	for density in Vegetation.density_classes.values():
		add_item(density.name)
		set_item_metadata(item_id, density)
		item_id += 1


func get_selected_class():
	return get_item_metadata(get_selected_id())
