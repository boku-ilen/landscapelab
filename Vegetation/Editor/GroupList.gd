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
		add_item(str(group.id) + ": " + group.name)
		set_item_metadata(item_id, group)
