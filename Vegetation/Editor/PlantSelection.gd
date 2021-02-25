extends VBoxContainer


func _ready():
	Vegetation.connect("new_data", self, "rebuild_list")
	$FilterContainer/PlantFilter.connect("item_selected", self, "_on_new_filter")
	
	rebuild_list()


func rebuild_list(filter=null):
	var plants = []
	
	if filter and not filter == "all":
		for plant in Vegetation.plants.values():
			if plant.type == filter:
				plants.append(plant)
	else:
		plants = Vegetation.plants.values()
	
	$PlantList.build_list(plants)


func _on_new_filter(id):
	rebuild_list($FilterContainer/PlantFilter.get_item_text(id))
