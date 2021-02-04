extends VSplitContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$PlantList.connect("item_selected", self, "_update_plant")


func _update_plant(selected_id: int):
	var plant = $PlantList.get_item_metadata(selected_id)
	$PlantDetails.set_plant(plant)
