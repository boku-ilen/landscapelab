extends ItemList


func build_list(plants):
	clear()
	
	for plant in plants:
		var item_id = get_item_count()
		add_item(plant.get_title_string())
		
#		set_item_icon(item_id, plant.get_icon_texture())
		set_item_metadata(item_id, plant)
