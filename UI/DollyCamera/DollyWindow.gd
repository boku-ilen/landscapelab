extends Window

#
# External window with a camera that follows a dolly rail 
# the rail can be set using controls from the external window
# in windows with action handerls
#

@export var scroll_step := 5.

var action_handlers: Array : set = on_set_handlers
var set_action: DollyAction
var dolly_cam: Camera3D


# DollyAction
# primary action => set point
# tertiary action => set focus
class DollyAction extends EditingAction:
	var set_focus = func(input: InputEvent, cursor, state_dict: Dictionary): 
		var pos = cursor.get_cursor_engine_position()
		dolly_scene.set_focus_position(pos, Vector3.UP * height_correction)
	var add_point = func(input: InputEvent, cursor, state_dict: Dictionary):
		var pos = cursor.get_cursor_engine_position()
		dolly_scene.add_path_point(pos + Vector3.UP * height_correction)
		point_count += 1
		dolly_scene.get_node("DollyRail/PathFollow3D/RemoteTransform3D").remote_path = dolly_cam.get_path()
		dolly_scene.toggle_cam(point_count > 1)
	
	# FIXME: this logic should be rewritten to be a line-feature
	var dolly_scene = load("res://Util/Imaging/Dolly/DollyScene.tscn").instantiate()
	var dolly_cam = load("res://Util/Imaging/Dolly/DollyCamera.tscn").instantiate()
	
	var height_correction := 0.0 : set = set_height_correction
	var point_count := 0
	
	func set_height_correction(new_height): height_correction = new_height
	
	func _init(viewport):
		super._init(add_point, func(a,s,d): pass, set_focus, true)
		dolly_scene.dolly_cam = dolly_cam
		viewport.add_child(dolly_scene)
		viewport.add_child(dolly_cam)


func on_set_handlers(handlers):
	action_handlers = handlers
	
	# Create the set action for new handlers
	set_action = DollyAction.new($Margin/VBox/SubViewportContainer/SubViewport)
	dolly_cam = set_action.dolly_cam
	
	# Connect ui-controls with the new action
	## The height at which the newly set point of the dollyrail will be above ground
	var spinbox = $Margin/VBox/ImagingMenu/VBoxContainer/SpinBox
	spinbox.value_changed.connect(set_action.set_height_correction)
	### Set with initial value
	set_action.set_height_correction(spinbox.value)
	
	## Clears the set path
	var clear = $Margin/VBox/ImagingMenu/Clear
	clear.pressed.connect(set_action.dolly_scene.clear)
	
	## Enables the set action for action handlers
	var set = $Margin/VBox/ImagingMenu/Set
	for handler in action_handlers:
		set.toggled.connect(func(toggled: bool):
			if toggled: handler.set_current_action(set_action)
			else: handler.stop_current_action())
	
	## If the button is toggled, the camera will follow the set focus
	var focus = $Margin/VBox/ImagingMenu/Focus
	focus.toggled.connect(func(toggled: bool): dolly_cam.focus_enabled = toggled)


# For usability reasons let the height_correction be controlled via mouse wheel
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value += scroll_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$Margin/VBox/ImagingMenu/VBoxContainer/SpinBox.value -= scroll_step
