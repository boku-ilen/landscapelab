extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	_build_list()


func _build_list():
	for plant in Vegetation.plants.values():
		var item_id = get_item_count()
		add_item(str(plant.id) + ": " + plant.name_en)
		
		set_item_icon(item_id, plant.get_billboard_texture())
		set_item_metadata(item_id, plant)
