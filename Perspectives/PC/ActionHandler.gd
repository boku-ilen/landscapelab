extends Node
class_name ActionHandler


var cursor: RayCast3D
var collision_indicator: Node3D
var player: AbstractPlayer

var current_action: Action
var current_cursor


# The string should precisely resemble a function in this script
func set_current_action(new_action: Action, new_cursor=null):
	current_action = new_action
	if cursor:
		current_cursor = new_cursor
		Input.set_custom_mouse_cursor(new_cursor)


func stop_current_action():
	current_action = null
	Input.set_custom_mouse_cursor(null)


# If an input comes, the player will check if the action handler has a pending
# action. If so it will call for this action. Otherwise it will handle input
# in it's usual manner.
func has_action() -> bool:
	return current_action != null

# Actions can be blocking (the playercontroller will not further handle the input)
func has_blocking_action() -> bool:
	return has_action() and current_action.is_blocking


# This should solely be used for things that need an input inside the player's
# script, and actually handles this via callbacks. Other functionalities that 
# do not require a direct input (e.g. viewshed) should be handled seperately.
func action(event):
	if has_action():
		current_action.apply(event)


# The action class, which can be extended from anywhere the class is needed
class Action:
	var player: AbstractPlayer
	var is_blocking: bool
	
	func _init(p,blocking):
		player = p
		is_blocking = blocking
	
	func apply(_event):
		pass


func enable_viewshed(enabled: bool):
	collision_indicator.get_node("Node/OmniLight3D").visible = enabled
