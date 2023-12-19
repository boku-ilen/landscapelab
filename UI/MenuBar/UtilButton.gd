extends MenuButton


@export var action_handler_3d_path: Node
@export var position_manager: PositionManager
const SCENE = preload("res://UI/DollyCamera/DollyWindow.tscn")

enum UtilOptions {
	IMAGING
}

enum ImagingOptions {
	OPEN
}

var imaging_options: PopupMenu
var dolly_window: Window
var previous_center_node: Node3D


func _ready():
	dolly_window = SCENE.instantiate()
	dolly_window.visible = false
	
	imaging_options = get_popup()
	
	dolly_window.action_handlers = [action_handler_3d_path]
	dolly_window.close_requested.connect(_cleanup_dolly)
	
	# Add options and store callback functions in metadata to call when 
	# the option is pressed
	imaging_options.add_item("Open", ImagingOptions.OPEN)
	imaging_options.set_item_metadata(ImagingOptions.OPEN, _begin_dolly)
	
	# Connect item pressed with callback
	imaging_options.index_pressed.connect(
		func(idx): imaging_options.get_item_metadata(idx).call())


func _begin_dolly():
	if not dolly_window.is_inside_tree():
		get_tree().get_root().add_child(dolly_window)
	
	dolly_window.popup()
	dolly_window.position_manager = position_manager
	
	imaging_options.set_item_disabled(ImagingOptions.OPEN, true)
	
	# Swap center node
	previous_center_node = position_manager.center_node
	position_manager.center_node = dolly_window.dolly_scene.dolly_cam


func _cleanup_dolly():
	# Reset center node
	position_manager.center_node = previous_center_node
	dolly_window.hide()
	imaging_options.set_item_disabled(ImagingOptions.OPEN, false)
