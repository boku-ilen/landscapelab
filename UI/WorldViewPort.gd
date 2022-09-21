extends SubViewportContainer


var pc_player :
	get:
		return pc_player
	set(player):
		for child in get_children():
			if "pc_player" in child:
				child.pc_player = player

func _ready():
	$FullscreenButton.connect("pressed",Callable(self,"on_fullscreen"))
	connect("focus_entered",Callable(self,"_disable_input").bind(false))
	connect("focus_exited",Callable(self,"_disable_input").bind(true))
	connect("mouse_entered",Callable(self,"_disable_input").bind(false))
	connect("mouse_exited",Callable(self,"_disable_input").bind(true))


func on_fullscreen():
	if !$SubViewport/World.is_fullscreen:
		$SubViewport/World.is_fullscreen = true
		var world = $SubViewport/World
		$SubViewport.remove_child(world)
		TreeHandler.switch_main_node(world)


func _enter_tree():
	if $SubViewport.get_child_count() == 0:
		var world = TreeHandler.state_stack.front()
		$SubViewport.add_child(world)


func _disable_input(disable: bool):
	logger.debug("Gui input disable: " + var_to_str(disable), "UI")
	$SubViewport.gui_disable_input = disable
	if disable and $SubViewport/World.has_node("FirstPersonPC"):
		$SubViewport/World/FirstPersonPC.stop_movement()
