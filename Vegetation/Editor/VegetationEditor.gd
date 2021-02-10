extends HSplitContainer


func _ready():
	$PlantPanel/PlantDetails/DetailList/GroupButton.connect("pressed", self, "_add_current_plant_to_current_group")
	$HSplitContainer/VBoxContainer/UpdateVisButton.connect("pressed", self, "_update_visualization")
	$HSplitContainer/GroupPanel/GroupDetails/GroupAttributes/Attributes/GroupPlantList.connect("item_selected", self, "_on_group_plant_selected")


func _add_current_plant_to_current_group():
	var current_plant = $PlantPanel/PlantDetails.current_plant
	var current_group = $HSplitContainer/GroupPanel/GroupDetails.current_group
	
	if current_plant and current_group:
		current_group.add_plant(current_plant)
		$HSplitContainer/GroupPanel/GroupDetails/GroupAttributes/Attributes/GroupPlantList.update_plants()


func _update_visualization():
	var current_group = $HSplitContainer/GroupPanel/GroupDetails.current_group
	
	if (current_group):
		$HSplitContainer/VBoxContainer/VisualizationUI/Viewport/Visualization.update_visualization(current_group.id)



func _on_group_plant_selected(selected_id: int):
	var plant = $HSplitContainer/GroupPanel/GroupDetails/GroupAttributes/Attributes/GroupPlantList.get_item_metadata(selected_id)
	$PlantPanel/PlantDetails.set_plant(plant)
