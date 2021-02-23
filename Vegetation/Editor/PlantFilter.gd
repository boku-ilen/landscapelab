extends OptionButton


func _ready():
	# Add item for no filtering
	add_item("all")
	
	# Get all possible values
	var types = []
	
	for plant in Vegetation.plants.values():
		if not plant.type in types:
			types.append(plant.type)
	
	# Add as options
	for type in types:
		add_item(type)
