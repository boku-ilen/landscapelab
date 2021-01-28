extends VSplitContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	$GroupList.connect("item_selected", self, "_update_group")
	$GroupDetails/GroupAttributes/Attributes/RemoveButton.connect("pressed", self, "_remove_current_selection")


func _remove_current_selection():
	var plant = $GroupDetails/GroupAttributes/Attributes/GroupPlantList.get_selected_plant()
	$GroupDetails.current_group.remove_plant(plant)
	
	$GroupDetails/GroupAttributes/Attributes/GroupPlantList.update_plants()


func _update_group(selected_id: int):
	var group = $GroupList.get_item_metadata(selected_id)
	
	$GroupDetails.set_group(group)
