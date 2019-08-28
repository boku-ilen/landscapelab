extends Node

#
# This node handles the different viewports and what's being displayed there.
# The available viewports are the PC main viewport, the PC mini viewport, and the
# VR viewport.
# By instantiating a scene into one of those viewports, the camera of that scene
# renders into this viewport.
# Thus, any perspective (scene with a camera) can be displayed in any viewport.
# Note that VR perspectives need to be built according to Godot's ARVR nodes.
#

# the available viewports
onready var pc_viewport = get_node("ViewportContainer/PCViewport")
onready var vr_viewport = get_node("ViewportContainer/VRViewport")
onready var pc_mini_viewport = get_node("UIMargin/MiniView/Border/Margin/MiniViewportContainer/Viewport")

var vr_activated : bool = false
var mouse_captured : bool = false

# These scenes contain the movement and rendering logic for their perspectives
var first_person_pc_scene = preload("res://Perspectives/PC/FirstPersonPC.tscn")
var third_person_pc_scene = preload("res://Perspectives/PC/ThirdPersonPC.tscn")
var first_person_vr_scene = preload("res://Perspectives/VR/FirstPersonVR.tscn")
var minimap_scene = preload("res://Perspectives/PC/Minimap/Minimap.tscn")

# here we remember what is shown in the full screen and miniview modes
var current_pc_scene
var current_pc_mini_scene


func _ready():
	# get the actual window dimensions and scale the PC viewports accordingly
	# TODO: If the window is resizeable, we may need to do this again if that happens!
	var screen_size = OS.get_window_size()
	var mini_size = screen_size / 3
	pc_viewport.size = screen_size
	
	# register the ui signals and bind them to the methods
	GlobalSignal.connect("miniview_close", self, "close_pc_mini_scene")
	GlobalSignal.connect("miniview_map", self, "change_pc_mini_scene", [minimap_scene])
	GlobalSignal.connect("miniview_1st", self, "change_pc_mini_scene", [first_person_pc_scene])
	GlobalSignal.connect("miniview_3rd", self, "change_pc_mini_scene", [third_person_pc_scene])
	GlobalSignal.connect("miniview_switch", self, "exchange_viewports")
	GlobalSignal.connect("toggle_follow_mode", self, "switch_follow_mode")
	GlobalSignal.connect("vr_enable", self, "toggle_vr", [true])
	GlobalSignal.connect("vr_disable", self, "toggle_vr", [false])
	
	# register minimap icon resize signal and bind to method
	GlobalSignal.connect("initiate_minimap_icon_resize", self, "relay_minimap_icon_resize")
	
	# Start with the minimap enabled
	current_pc_scene = third_person_pc_scene  # this is necessairy so no double signals are emitted by accident
	change_pc_mini_scene(minimap_scene)
	
	# Start with PC 3rd person view
	change_pc_scene(third_person_pc_scene)


# Check for perspective-related input and react accordingly
func _unhandled_input(event):
	if event.is_action_pressed("toggle_mouse_capture"):
		toggle_mouse_capture()


func toggle_mouse_capture():
	if mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	mouse_captured = !mouse_captured


# Remove the current VR controller and (re-)add it if it's activated
func toggle_vr(enabled):
	vr_activated = enabled
	
	if vr_activated:
		change_pc_mini_scene(first_person_vr_scene)
		pc_mini_viewport.arvr = true
		pc_mini_viewport.hdr = false
	else:
		pc_mini_viewport.arvr = false
		pc_mini_viewport.hdr = true


# change the scene of the miniview to given scene
func change_pc_mini_scene(scene, emit=true):
	# notify the ui about reenabeling the miniview 
	if current_pc_mini_scene == null:
		GlobalSignal.emit_signal("miniview_show")	
	
	# replace the current scene with the new one
	for child in pc_mini_viewport.get_children():
		child.free()
	pc_mini_viewport.add_child(scene.instance())
	current_pc_mini_scene = scene
	if emit:
		emit_missing_viewports()
	GlobalSignal.emit_signal("initiate_minimap_icon_resize", get_minimap_status() , filename)
	

# change the scene of the pc fullscreen to given scene
func change_pc_scene(scene):
	for child in pc_viewport.get_children():
		child.free()
	pc_viewport.add_child(scene.instance())
	current_pc_scene = scene
	emit_missing_viewports()
	GlobalSignal.emit_signal("initiate_minimap_icon_resize", get_minimap_status(), filename)


# this clears the miniview
func close_pc_mini_scene():
	for child in pc_mini_viewport.get_children():
		child.free()	
	current_pc_mini_scene = null
	emit_missing_viewports()


# switch the scenes of the two pc viewports (fullscreen and miniview)
func exchange_viewports():	
	var new_pc = current_pc_mini_scene
	var new_mini = current_pc_scene
	change_pc_mini_scene(new_mini, false)
	change_pc_scene(new_pc)


func emit_missing_viewports():
	if (minimap_scene != current_pc_mini_scene and minimap_scene != current_pc_scene):
		GlobalSignal.emit_signal("missing_map")
	if (first_person_pc_scene != current_pc_mini_scene and first_person_pc_scene != current_pc_scene):
		GlobalSignal.emit_signal("missing_1st")
	if (third_person_pc_scene != current_pc_mini_scene and third_person_pc_scene != current_pc_scene):
		GlobalSignal.emit_signal("missing_3rd")


# sends signal with minimap size and status so that minimap icons can rescale accordingly
func relay_minimap_icon_resize(value, initiator):
	if initiator != filename:
		GlobalSignal.emit_signal("minimap_icon_resize", value, get_minimap_status())


func get_minimap_status():
	var status = 'none'
	if current_pc_mini_scene == minimap_scene:
		status = 'small'
	if current_pc_scene == minimap_scene:
		status = 'big'
	return status


func switch_follow_mode():
	PlayerInfo.is_follow_enabled = !PlayerInfo.is_follow_enabled
