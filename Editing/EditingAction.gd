extends RefCounted
class_name EditingAction

#
# This class should be overwritten by an action (e.g. from geolayer-editing),
# which needs to be processed in a kind of viewport.
# each action (primary, secondary, tertiary) is bound to a input method in 
# a given perspective. If an action should not be available in one perspective,
# remove the corresponding flag.
#

# Will be emitted once the action goes active
signal active_changed(is_active: bool)

# Type hinting arguments/returns of callables is not possible
# this action will always obtain an InputEvent and a AbstractCursor (although
# duck typed, since it a Cursor can be 3D and 2D) plus the internal state-dict
# of the class. With this simple state operations can be achieved without
# extending the class.
# Called via: action.call(event, cursor, current_action.state_dict)
var primary_action: Callable
var secondary_action: Callable
var tertiary_action: Callable

# To be able to maintain a state while editing
var state_dict: Dictionary
var custom_cursor: Resource = null
# If other input events (e.g. movement) shall be performed or blocked while editing
var is_blocking: bool
var is_active: bool
# To add a default argument in init which represents the signature
var empty_func = func(a, b, c): return
# Many actions require some form of input field; this window will be popped any
# time the action is activated
var input_window: Window


func _init(primary: Callable, secondary: Callable = empty_func, 
		tertiary: Callable = empty_func, blocking: bool = true, cursor_texture: Texture2D = null):
	primary_action = primary
	secondary_action = secondary
	tertiary_action = tertiary
	is_blocking = blocking
	custom_cursor = cursor_texture
	state_dict = {}


# NEEDS TO BE CALLED MANUALLY 
func set_action_active(active: bool):
	is_active = active
	active_changed.emit(active)
	if input_window != null:
		input_window.visible = true


# In case an editing action needs more specific actions, override in inherited
# An ActionHandler will first check primary, secondary and tertiary, before
# calling this function. 
func special_action(event: InputEvent, cursor): pass
