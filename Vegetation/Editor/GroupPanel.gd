extends VSplitContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$GroupList.connect("item_selected", self, "_update_group")


func _update_group(selected_id: int):
	var group = $GroupList.get_item_metadata(selected_id)
	
	$GroupDetails.set_group(group)
