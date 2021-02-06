extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	_build_list()


func _build_list():
	for group in Vegetation.groups.values():
		var item_id = get_item_count()
		add_item(str(group.id) + ": " + group.name)
		set_item_metadata(item_id, group)
