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
	var world = get_node("WorldViewPort/SubViewport/World")
	
	if not world.is_fullscreen:
		world.is_fullscreen = true
		$WorldViewPort/SubViewport.remove_child(world)
		TreeHandler.switch_main_node(world)
