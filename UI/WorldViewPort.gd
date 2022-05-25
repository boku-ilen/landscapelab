extends ViewportContainer


var pc_player setget set_pc_player 


func set_pc_player(player: AbstractPlayer):
	for child in get_children():
		if "pc_player" in child:
			child.pc_player = player


func _ready():
	$FullscreenButton.connect("pressed", self, "on_fullscreen")
	connect("focus_entered", self, "_disable_input", [false])
	connect("focus_exited", self, "_disable_input", [true])
	connect("mouse_entered", self, "_disable_input", [false])
	connect("mouse_exited", self, "_disable_input", [true])


func on_fullscreen():
	if !$Viewport/World.is_fullscreen:
		$Viewport/World.is_fullscreen = true
		var world = $Viewport/World
		$Viewport.remove_child(world)
		TreeHandler.switch_main_node(world)


func _enter_tree():
	if $Viewport.get_child_count() == 0:
		var world = TreeHandler.state_stack.front()
		$Viewport.add_child(world)


func _disable_input(disable: bool):
	logger.debug("Gui input disable: " + String(disable), "UI")
	$Viewport.gui_disable_input = disable
	if disable and $Viewport/World.has_node("FirstPersonPC"):
		$Viewport/World/FirstPersonPC.stop_movement()
