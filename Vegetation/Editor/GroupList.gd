extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	Vegetation.connect("new_data", self, "_build_list")
	
	# Initial build - this node is created after the new_data signal is first emitted
	_build_list()


func _build_list():
	clear()
	
	for group in Vegetation.groups.values():
		var item_id = get_item_count()
		add_item(str(group.id) + ": " + group.name_en)
		set_item_metadata(item_id, group)
		_update_background(item_id)


# Highlight a group depending on the number of plants in it
func _update_background(id):
	if get_item_metadata(id).plants.size() > 0:
		set_item_custom_bg_color(id, Color(0.1, 0.3, 0.1, min(get_item_metadata(id).plants.size() / 15.0, 3.0)))


func update_background_of_selected():
	if get_selected_items().size() > 0:
		_update_background(get_selected_items()[0])
