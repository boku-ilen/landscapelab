extends ItemList


var current_group


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_plants(group = current_group):
	current_group = group
	
	clear()
	
	for plant in current_group.plants:
		var item_id = get_item_count()
		add_item(str(plant.id) + ": " + plant.name_en)
		
		set_item_icon(item_id, plant.get_billboard_texture())
		set_item_metadata(item_id, plant)
