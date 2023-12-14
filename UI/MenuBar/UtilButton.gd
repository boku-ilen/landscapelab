extends MenuButton


@export var action_handler_3d_path: Node
@export var position_manager: Node
const SCENE = preload("res://UI/DollyCamera/DollyWindow.tscn")

enum UtilOptions {
	IMAGING
}

enum ImagingOptions {
	OPEN,
	SET_FULLSCREEN
}

var imaging_options: PopupMenu
var imaging_scene: Window
var previous_center_node: Node3D

func _ready():
	imaging_scene = SCENE.instantiate()
	imaging_scene.visible = false
	
	imaging_options = get_popup()
	
	imaging_scene.action_handlers = [action_handler_3d_path]
	imaging_scene.close_requested.connect(func():
		_cleanup_dolly
		imaging_options.set_item_disabled(ImagingOptions.OPEN, false))
	
	# Add options and store callback functions in metadata to call when 
	# the option is pressed
	imaging_options.add_item("Open", ImagingOptions.OPEN)
	imaging_options.set_item_metadata(ImagingOptions.OPEN, _begin_dolly)
	
	imaging_options.add_item("Set Fullscreen", ImagingOptions.SET_FULLSCREEN)
	imaging_options.set_item_disabled(ImagingOptions.SET_FULLSCREEN, true)
	imaging_options.set_item_as_checkable(ImagingOptions.SET_FULLSCREEN, true)
	imaging_options.set_item_checked(ImagingOptions.SET_FULLSCREEN, false)
	imaging_options.set_item_metadata(ImagingOptions.SET_FULLSCREEN, func():
		if imaging_scene.mode == Window.MODE_FULLSCREEN:
			imaging_scene.mode = Window.MODE_WINDOWED
			imaging_options.set_item_checked(ImagingOptions.SET_FULLSCREEN, false)
		else:
			imaging_scene.mode = Window.MODE_FULLSCREEN
			imaging_options.set_item_checked(ImagingOptions.SET_FULLSCREEN, true))
	
	# Connect item pressed with callback
	imaging_options.index_pressed.connect(
		func(idx): imaging_options.get_item_metadata(idx).call())


func _begin_dolly():
	if not imaging_scene.is_inside_tree():
		get_tree().get_root().add_child(imaging_scene)
	
	# Set starting position where we currently are
	# otherwise it will load the terrain at position=Vector3.ZERO
	imaging_scene.dolly_cam.position = position_manager.center_node.position
	
	imaging_options.set_item_disabled(ImagingOptions.OPEN, true)
	imaging_options.set_item_disabled(ImagingOptions.SET_FULLSCREEN, false)
	
	imaging_scene.popup()
	
	# Swap center node
	previous_center_node = position_manager.center_node
	position_manager.center_node = imaging_scene.dolly_cam


func _cleanup_dolly():
	# Reset center node
	position_manager.center_node = previous_center_node
	imaging_scene.hide()
