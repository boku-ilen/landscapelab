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

onready var pc_viewport = get_node("ViewportContainer/PCViewport")
onready var vr_viewport = get_node("ViewportContainer/VRViewport")
onready var pc_mini_viewport = get_node("ViewportContainer/MiniViewportContainer/PCMiniViewport")
onready var pc_mini_container = get_node("ViewportContainer/MiniViewportContainer")

var vr_activated : bool = false
var minimap_activated : bool = false
var mouse_captured : bool = false

# These scenes contain the movement and rendering logic for their perspectives
var first_person_pc_scene = preload("res://Perspectives/PC/FirstPersonPC.tscn")
var third_person_pc_scene = preload("res://Perspectives/PC/ThirdPersonPC.tscn")

var first_person_vr_scene = preload("res://Perspectives/VR/FirstPersonVR.tscn")

var minimap_scene = preload("res://Perspectives/PC/Minimap/Minimap.tscn")


func _ready():
	# get the actual window dimensions and scale the PC viewports accordingly
	# TODO: If the window is resizeable, we may need to do this again if that happens!
	var screen_size = OS.get_window_size()
	var mini_size = screen_size / 3
	
	pc_viewport.size = screen_size
	pc_mini_viewport.size = mini_size
	pc_mini_container.rect_size = mini_size
	pc_mini_container.rect_position = screen_size - mini_size
	
	# Start with PC 3rd person view
	pc_activate_third_person()
	# Start with the minimap enabled
	# toggle_minimap()  


# Check for perspective-related input and react accordingly
func _input(event):
	if event.is_action_pressed("pc_activate_first_person"):
		pc_activate_first_person()
	elif event.is_action_pressed("pc_activate_third_person"):
		pc_activate_third_person()
	elif event.is_action_pressed("toggle_vr"):
		toggle_vr()
	elif event.is_action_pressed("toggle_minimap"):
		toggle_minimap()
	elif event.is_action_pressed("toggle_mouse_capture"):
		toggle_mouse_capture()


# Instance the first person controller for the PC viewport
func pc_activate_first_person():
	clear_pc()
	add_pc(first_person_pc_scene.instance()) # TODO: This causes Error "Condition ' !is_inside_tree() ' is true. returned: Transform()", which has no apparent implication
	add_pc_mini(minimap_scene.instance())
	
	if vr_activated:
		pass # Set PC movement false, stick to VR player
	else:
		pass # Set PC movement free


# Instance the third person controller for the PC viewport
func pc_activate_third_person():
	clear_pc()
	add_pc(third_person_pc_scene.instance())


# toggle the display of the minimap
func toggle_minimap():
	minimap_activated = !minimap_activated	
	if minimap_activated:
		pc_viewport.add_child(minimap_scene.instance())


func toggle_mouse_capture():
	if mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	mouse_captured = !mouse_captured


# Add the VR controller to the VR viewport
func toggle_vr():
	clear_vr()
	vr_activated = !vr_activated
	
	if vr_activated:
		add_vr(first_person_vr_scene.instance())
	
	# Reload PC viewport
	pc_activate_first_person()


# Adds any scene to the viewport which renders to the PC's monitor
func add_pc(scene):
	pc_viewport.add_child(scene)
	

# Adds any scene to the secondary, smaller viewport on the PC's monitor (e.g. minimap)
func add_pc_mini(scene):
	pc_mini_viewport.add_child(scene)


# Adds any scene to the viewport which renders to the VR headset
func add_vr(scene):
	vr_viewport.add_child(scene)


# Remove all scenes which render to the PC's monitor
func clear_pc():
	for child in pc_viewport.get_children():
		child.free()
		
		
# Remove all scenes which render to the PC's secondary view
func clear_pc_mini():
	for child in pc_mini_viewport.get_children():
		child.free()


# Remove all scenes which render to the VR headset
func clear_vr():
	for child in vr_viewport.get_children():
		child.free()