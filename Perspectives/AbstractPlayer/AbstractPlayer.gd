extends KinematicBody
class_name AbstractPlayer

var dragging : bool = false
var rotating : bool = false

var mouse_position_before_capture: Vector2

var mouse_sensitivity = Settings.get_setting("player", "mouse-sensitivity")

var position_manager: PositionManager  # Injected if needed

const LOG_MODULE := "PERSPECTIVES"


func teleport(pos: Vector3):
	logger.info("Teleporting player %s to coordinates: %s" % [name, pos], LOG_MODULE)
	transform.origin = pos


# As in some cases the actual orientation node might be different, define this as function to
# be overwritten
func get_orientation_basis():
	return transform.basis


func get_look_direction() -> Vector3:
	return -transform.basis.z


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
			set_mouse_mode_captured()
			get_tree().set_input_as_handled()
			return true
		elif event.button_index == BUTTON_RIGHT:
			rotating = true
			set_mouse_mode_captured()
			get_tree().set_input_as_handled()
			return true
	elif event is InputEventMouseMotion:
		# If the mouse is currently active, remember the mouse position in case it gets captured
		#  next frame. This is done here because the global mouse position is only obtainable
		#  from an InputEventMouse, it can't be received outside of _input.
		# (get_viewport().get_mouse_position() returns the position relative to that viewport, which
		#  is not what we want.)
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			mouse_position_before_capture = event.get_global_position()

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
			if not rotating: set_mouse_mode_free()
			
			return true
		elif event.button_index == BUTTON_RIGHT and rotating:
			rotating = false
			if not dragging: set_mouse_mode_free()
			
			return true


# Handle input which should always have an effect, even if the mouse isn't over this viewport
# Can be implemented for additional input
func _handle_general_input(event):
	pass


# To prevent floating point errors, the player.translation does not reflect the player's 
# actual position in the whole world. This function returns the true world position of 
# the player (in projected meters) as integers.
func get_true_position():
	return position_manager.to_world_coordinates(translation)


# Set the position from projected meter coordinates in an int array
func set_true_position(pos):
	translation = position_manager.to_engine_coordinates(pos) + Vector3.UP * 500.0


# Lock the mosue to the window and make it invisible.
func set_mouse_mode_captured():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# (The position is remembered by _handle_abstract_viewport_input)


# Unlock the mouse and make it freely movable as usual. Also, return it to the position it was at
#  before being captured.
func set_mouse_mode_free():
	# Hide the mouse while teleporting it back to where it was before being captured
	# (warping during MOUSE_MODE_CAPTURED has no effect)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.warp_mouse_position(mouse_position_before_capture)
	
	# Make it visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
