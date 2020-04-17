extends "res://addons/godot-openvr/scenes/ovr_main.gd"
#tool

#
# This script sets up the VR player, as described in
# https://github.com/GodotVR/godot-openvr-asset.
#

export(PackedScene) var vr_menu
export(PackedScene) var objects_menu
export(bool) var show_controller_left setget set_show_controller_left
export(bool) var show_controller_right setget set_show_controller_right
export(bool) var show_hand_left setget set_show_hand_left
export(bool) var show_hand_right setget set_show_hand_right

onready var controller_left = get_node("LeftVisual")
onready var controller_right = get_node("RightVisual")
onready var hand_left = get_node("Left/Tip/Gestures")
onready var hand_right = get_node("Right/Tip/Gestures")

var interface


func set_show_controller_left(is_visible):
	show_controller_left = is_visible
	#get_node("LeftVisual").show_controller_mesh = show_controller_left


func set_show_controller_right(is_visible):
	show_controller_right = is_visible
	#get_node("RightVisual").show_controller_mesh = show_controller_right


func set_show_hand_left(is_visible):
	show_hand_left = is_visible
	#get_node("Left/Tip/Gestures").visible = show_hand_left


func set_show_hand_right(is_visible):
	show_hand_right = is_visible
	#get_node("Right/Tip/Gestures").visible = show_hand_right


func set_show_meshes(side: int, show_controller: bool, show_hand: bool):
	if side == 1:
		set_show_controller_left(show_controller)
		set_show_hand_left(show_hand)
	elif side == 2:
		set_show_controller_right(show_controller)
		set_show_hand_right(show_hand)


func get_show_meshes(side: int):
	if side == 1:
		return {"hand": show_hand_left, "controller": show_controller_left}
	elif side == 2:
		return {"hand": show_hand_right, "controller": show_controller_right}


func _ready():
	#set_show_controller_left(show_hand_left)
	#set_show_controller_right(show_hand_right)
	#set_show_hand_left(show_hand_left)
	#set_show_hand_right(show_hand_right)
	controller_left.show_controller_mesh = show_controller_left
	controller_right.show_controller_mesh = show_controller_right
	hand_left.visible = show_hand_left
	hand_right.visible = show_hand_right
	
	GlobalVRAccess.controller_id_dict[controller_left.controller_id] = controller_left
	GlobalVRAccess.controller_id_dict[controller_right.controller_id] = controller_right
	
	#init_object_menu()
	#init_vr_menu()
	
	logger.info("Successfully initialized VR")





func init_vr_menu():
	var vr_menu_mesh = preload("res://addons/vr-toolkit/Gui/GuiToCurved.tscn").instance()
	vr_menu_mesh.viewport_element = vr_menu
	vr_menu_mesh.rotation_degrees.x = 90
	vr_menu_mesh.visible = false
	add_child(vr_menu_mesh)
	GlobalVRAccess.vr_menus.append(vr_menu_mesh)


func init_object_menu():
	var instance = objects_menu.instance()
	GlobalVRAccess.object_menu = instance
	instance.visible = false
	add_child(instance)
