extends Node


#
# Simplification for switching around between different scnens/nodes
#


var state_stack = []


func switch_main_node(new_node):
	print(get_tree().get_current_scene())
	state_stack.push_front(get_tree().get_current_scene())
	
	get_tree().get_root().remove_child(state_stack.front())
	get_tree().get_root().add_child(new_node)
	get_tree().current_scene = new_node
	print(state_stack)


func switch_last_state():
	switch_main_node(state_stack.pop_front())


func append_state(state):
	state_stack.push_front(state)
