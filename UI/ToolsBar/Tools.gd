extends VBoxContainer


onready var tools_bar = get_node("ToolsBar")
onready var popups = get_node("Popups")


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in tools_bar.get_children():
		if child.name != "Hoverable":
			var has_required_property = true
			if not "popups_container" in child:
				has_required_property = false
				
			assert(has_required_property)
			
			child.set_popups_container(popups)
