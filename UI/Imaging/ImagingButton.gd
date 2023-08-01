extends AutoIconButton

@export var action_handler_3d_path: NodePath
@export var position_manager_path: NodePath

var previous_center_node


func _ready():
	$Window.action_handlers = [get_node(action_handler_3d_path)]
	
	pressed.connect(_begin_dolly)
	$Window.close_requested.connect(_cleanup_dolly)


func _begin_dolly():
	$Window.popup()
	
	# Swap center node
	previous_center_node = get_node(position_manager_path).center_node
	get_node(position_manager_path).center_node = $Window/Margin/VBox/SubViewportContainer/SubViewport/DollyCamera


func _cleanup_dolly():
	# Reset center node
	get_node(position_manager_path).center_node = previous_center_node
	
	$Window.hide()
