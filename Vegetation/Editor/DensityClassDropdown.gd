extends OptionButton


func _ready():
	# Add all density classes
	# TODO: Automatically get these from Vegetation
	add_item("S_PLANT")
	add_item("M_PLANT")
	add_item("L_PLANT")
	add_item("XL_PLANT")
	add_item("S_TREE")
	add_item("L_TREE")


func get_selected_class():
	var selected_string = get_item_text(get_selected_id())
	return Vegetation.parse_density_class(selected_string)
