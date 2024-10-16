extends SubViewportContainer




func _ready():
	connect("focus_entered",Callable(self,"_disable_input").bind(false))
	connect("focus_exited",Callable(self,"_disable_input").bind(true))
	connect("mouse_entered",Callable(self,"_disable_input").bind(false))
	connect("mouse_exited",Callable(self,"_disable_input").bind(true))


func _disable_input(disable: bool):
	logger.debug("Gui input disable: " + var_to_str(disable))
	$SubViewport.gui_disable_input = disable
	if disable and $SubViewport/World.has_node("FirstPersonPC"):
		$SubViewport/World/FirstPersonPC.stop_movement()
