extends Node

onready var pc_viewport = get_node("ViewportContainer/PCViewport")
onready var vr_viewport = get_node("ViewportContainer/VRViewport")

var vr_activated : bool = false

# These scenes contain the movement and rendering logic for their perspectives
var first_person_pc_scene = preload("res://Perspectives/PC/FirstPersonPC.tscn")
var third_person_pc_scene = preload("res://Perspectives/PC/ThirdPersonPC.tscn")

var first_person_vr_scene = preload("res://Perspectives/VR/FirstPersonVR.tscn")

func _ready():
	# Start with PC first person view
	pc_activate_first_person()

# Check for perspective-related input and react accordingly
func _input(event):
	if event.is_action_pressed("pc_activate_first_person"):
		pc_activate_first_person()
	elif event.is_action_pressed("pc_activate_third_person"):
		pc_activate_third_person()
	elif event.is_action_pressed("toggle_vr"):
		toggle_vr()

# Instance the first person controller for the PC viewport
func pc_activate_first_person():
	clear_pc()
	add_pc(first_person_pc_scene.instance()) # TODO: This causes Error "Condition ' !is_inside_tree() ' is true. returned: Transform()", which has no apparent implication
	
	if vr_activated:
		pass # Set PC movement false, stick to VR player
	else:
		pass # Set PC movement free

# Instance the third person controller for the PC viewport
func pc_activate_third_person():
	clear_pc()
	add_pc(third_person_pc_scene.instance())

# Add the VR controller to the VR viewport
func toggle_vr():
	clear_vr()
	vr_activated = !vr_activated
	
	if vr_activated:
		pass
		add_vr(first_person_vr_scene.instance())
	
	# Reload PC viewport
	pc_activate_first_person()

# Adds any scene to the viewport which renders to the PC's monitor
func add_pc(scene):
	pc_viewport.add_child(scene)

# Adds any scene to the viewport which renders to the VR headset
func add_vr(scene):
	vr_viewport.add_child(scene)

# Remove all scenes which render to the PC's monitor
func clear_pc():
	for child in pc_viewport.get_children():
		child.free()

# Remove all scenes which render to the VR headset
func clear_vr():
	for child in vr_viewport.get_children():
		child.free()