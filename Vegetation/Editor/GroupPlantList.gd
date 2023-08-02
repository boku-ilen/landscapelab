extends ItemList


var current_group


func get_selected_plant():
	var selection = get_selected_items()
	
	if selection.size() == 1:
		var id = selection[0]
		return get_item_metadata(id)


func update_plants(group = current_group):
	current_group = group
	
	clear()
	
	for plant in current_group.plants:
		var item_id = get_item_count()
		add_item(plant.get_title_string())
		
#		set_item_icon(item_id, plant.get_icon_texture())
		set_item_metadata(item_id, plant)
