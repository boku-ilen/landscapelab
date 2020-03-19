extends Spatial

#
# This script sets up the VR player, as described in
# https://github.com/GodotVR/godot-openvr-asset.
#

export(PackedScene) var vr_menu

onready var controller1 = get_node("ARVROrigin/OVRController")
onready var controller2 = get_node("ARVROrigin/OVRController2")

var interface


func _ready():
	GlobalVRAccess.controller_id_dict[controller1.controller_id] = controller1
	GlobalVRAccess.controller_id_dict[controller2.controller_id] = controller2
	
	interface = ARVRServer.find_interface("OpenVR")
	
	if interface and interface.initialize():
		# turn off vsync, we'll be using the headsets vsync
		OS.vsync_enabled = false
		
		# change our physics fps
		Engine.target_fps = 90
		
		# make sure HDR rendering is off (not applicable for GLES2 renderer), VR rendering is true
		# TODO: Ideally the VR player inherits from AbstractPlayer, which already handles this!
		#logger.debug("Setting up viewport for VR")
		
		# Required viewport settings
		get_viewport().arvr = true
		get_viewport().render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
		get_viewport().render_target_update_mode = Viewport.UPDATE_ALWAYS
		get_viewport().keep_3d_linear = true  # OpenVR handles sRGB conversion for us
		get_viewport().msaa = get_viewport().MSAA_2X  # The VR display needs good anti-aliasing
		
		init_menu()


func cleanup():
	interface.uninitialize()
	
	get_viewport().arvr = false
	get_viewport().keep_3d_linear = false
	get_viewport().set_size_override(false)


func init_menu():
	var vr_menu_mesh = preload("res://addons/vr-toolkit/Gui/GuiToCurved.tscn").instance()
	vr_menu_mesh.viewport_element = vr_menu
	vr_menu_mesh.rotation_degrees.x = 90
	vr_menu_mesh.visible = false
	add_child(vr_menu_mesh)
	GlobalVRAccess.vr_menus.append(vr_menu_mesh)
