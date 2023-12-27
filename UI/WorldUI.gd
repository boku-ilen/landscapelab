extends Control


var pc_player :
	get:
		return pc_player
	set(player):
		for child in get_children():
			if "pc_player" in child:
				child.pc_player = player


func _enter_tree():
	if TreeHandler.state_stack.front() == null \
	or TreeHandler.state_stack.front() == self:
			return
	
	var world_viewport = TreeHandler.state_stack.front()
	add_child(world_viewport)


func on_fullscreen():
	var world_viewport = get_node("WorldViewPort")
	var world = world_viewport.get_node("SubViewport/World")
	
	if not world.is_fullscreen:
		world.is_fullscreen = true
		remove_child(world_viewport)
		TreeHandler.switch_main_node(world_viewport)
