extends Node
class_name ActionHandler

# E.g. 2D, 3D, VR
@export var perspective_prefix: String
@export_node_path var cursor_path
@onready var cursor = get_node(cursor_path)

var current_action: EditingAction


func set_current_action(action: EditingAction) -> void:
	current_action = action
	if action.custom_cursor != null:
		Input.set_custom_mouse_cursor(action.custom_cursor)


func stop_current_action() -> void:
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
		if event.is_action_pressed("{}_primary_action".format([perspective_prefix], "{}")):
			current_action.primary_action.call(event, cursor, current_action.state_dict)
		elif event.is_action_pressed("{}_secondary_action".format([perspective_prefix], "{}")):
			current_action.secondary_action.call(event, cursor, current_action.state_dict)
		elif event.is_action_pressed("{}_tertiary_action".format([perspective_prefix], "{}")):
			current_action.tertiary_action.call(event, cursor, current_action.state_dict)
		else:
			current_action.special_action(event, cursor)
