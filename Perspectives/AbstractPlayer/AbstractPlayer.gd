extends KinematicBody
class_name AbstractPlayer

var has_moved : bool = true
export var is_main_perspective : bool

var dragging : bool = false
var rotating : bool = false

var mouse_sensitivity = Settings.get_setting("player", "mouse-sensitivity")


func _ready():
	Offset.connect("shift_world", self, "shift")
	
	if is_main_perspective:
		PlayerInfo.is_main_active = true


# This is a function that can handle notification, we will use it for "destructor"-purposes
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_main_perspective:
        	PlayerInfo.is_main_active = false


func _physics_process(delta):
	if has_moved and is_main_perspective:
		PlayerInfo.update_player_pos(translation)
		has_moved = false
	else:
		if PlayerInfo.is_follow_enabled:
			translation.x = PlayerInfo.get_engine_player_position().x
			translation.z = PlayerInfo.get_engine_player_position().z


func _unhandled_input(event):
	# Check abstract general input, then overwritten general input, then abstract viewport input,
	#  then overwritten viewport input
	# If the input was handled by one of the functions, it is marked handled and the function is exited.
	var handled = _handle_abstract_general_input(event)
	
	if handled:
		return

	handled = _handle_general_input(event)
	
	if handled:
		return
	
	if get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
		handled = _handle_abstract_viewport_input(event)
		
		if handled:
			return
		
		_handle_viewport_input(event)


# Handle input which should only have an effect when the mouse is inside the viewport
# Input for all Player classes - do not overwrite!
func _handle_abstract_viewport_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT: 
			dragging = true
			get_tree().set_input_as_handled()
			return true
		elif event.button_index == BUTTON_RIGHT:
			rotating = true
			get_tree().set_input_as_handled()
			return true

# Handle input which should only have an effect when the mouse is inside the viewport
# Can be implemented for additional input
func _handle_viewport_input(event):
	pass


# Handle input which should always have an effect, even if the mouse isn't over this viewport
# Example: Releasing the mouse should always stop the current action, regardless of where it is
# Input for all Player classes - do not overwrite!
func _handle_abstract_general_input(event):
	# Mouse button release
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == BUTTON_LEFT:
			dragging = false
			return true
		elif event.button_index == BUTTON_RIGHT:
			rotating = false
			return true


# Handle input which should always have an effect, even if the mouse isn't over this viewport
# Can be implemented for additional input
func _handle_general_input(event):
	pass


# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta_x, delta_z):
	if is_main_perspective or not PlayerInfo.is_main_active:
		PlayerInfo.add_player_pos(Vector3(delta_x, 0, delta_z))
	
	translation.x += delta_x
	translation.z += delta_z