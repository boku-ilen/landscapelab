extends ViewportContainer


func _ready():
	$FullscreenButton.connect("pressed", self, "on_fullscreen")
	$Viewport/World.connect("fullscreen_off", self, "exit_fullscreen")
	connect("focus_entered", self, "_disable_in_input", [false])
	connect("focus_exited", self, "_disable_in_input", [true])


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


func _disable_in_input(disable: bool):
	print("Gui input disable: " + String(disable))
	$Viewport.gui_disable_input = disable
