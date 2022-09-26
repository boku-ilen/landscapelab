extends Control


var pc_player :
	get:
		return pc_player
	set(player):
		for child in get_children():
			if "pc_player" in child:
				child.pc_player = player


func _ready():
	get_node("FullscreenButton").connect("pressed",Callable(self,"on_fullscreen"))


func on_fullscreen():
	if !$SubViewport/World.is_fullscreen:
		$SubViewport/World.is_fullscreen = true
		var world = $SubViewport/World
		$SubViewport.remove_child(world)
		TreeHandler.switch_main_node(world)
