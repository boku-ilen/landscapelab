extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	UISignal.connect("set_viewshed_tool", self, "_on_set_viewshed_tool")


func _on_set_viewshed_tool(enabled: bool):
	get_node("OmniLight").visible = enabled
