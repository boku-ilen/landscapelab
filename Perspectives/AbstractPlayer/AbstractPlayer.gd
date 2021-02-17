extends KinematicBody
class_name AbstractPlayer

var dragging : bool = false
var rotating : bool = false

var mouse_sensitivity = Settings.get_setting("player", "mouse-sensitivity")

var position_manager: PositionManager


func _input(event):
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
		if event.button_index == BUTTON_LEFT and not rotating: 
			dragging = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().set_input_as_handled()
			return true
		elif event.button_index == BUTTON_RIGHT:
			rotating = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
		if event.button_index == BUTTON_LEFT and dragging:
			dragging = false
			if not rotating: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			return true
		elif event.button_index == BUTTON_RIGHT and rotating:
			rotating = false
			if not dragging: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			return true


# Handle input which should always have an effect, even if the mouse isn't over this viewport
# Can be implemented for additional input
func _handle_general_input(event):
	pass


# Shift the player's in-engine translation by a certain offset, but not the player's true coordinates.
func shift(delta_x, delta_z):
	translation.x += delta_x
	translation.z += delta_z


# To prevent floating point errors, the player.translation does not reflect the player's 
# actual position in the whole world. This function returns the true world position of 
# the player (in projected meters) as integers.
func get_true_position():
	return translation  # TODO: Implement properly using PositionManager
