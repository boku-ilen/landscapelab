extends Node
class_name ActionHandler

# E.g. 2D, 3D, VR
@export var perspective_prefix: String
@export_node_path var cursor_path
@onready var cursor = get_node(cursor_path)

var current_action: EditingAction


# The action class, which can be extended from anywhere the class is needed
class Action:
	var player: AbstractPlayer
	var is_blocking: bool
	
	func _init(p,blocking):
		player = p
		is_blocking = blocking
	
	func apply(_event):
		pass


func set_current_action(action: EditingAction) -> void:
	current_action = action
	action.set_action_active(true)
	if action.custom_cursor != null:
		Input.set_custom_mouse_cursor(action.custom_cursor)


func stop_current_action() -> void:
	current_action.set_action_active(false)
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


func handle(event: InputEvent) -> void:
	if has_action():
		if event.is_action_released("{}_primary_action".format([perspective_prefix], "{}")):
			current_action.primary_action.call(event, cursor, current_action.state_dict)
		elif event.is_action_released("{}_secondary_action".format([perspective_prefix], "{}")):
			current_action.secondary_action.call(event, cursor, current_action.state_dict)
		elif event.is_action_released("{}_tertiary_action".format([perspective_prefix], "{}")):
			current_action.tertiary_action.call(event, cursor, current_action.state_dict)
		else:
			current_action.special_action(event, cursor)
