extends AutoIconButton

@export var action_handler_3d_path: NodePath
@export var position_manager_path: NodePath


func _ready():
	pressed.connect(_begin_dolly)


func _begin_dolly():
	$Window.popup()
	$Window.action_handlers = [get_node(action_handler_3d_path)]
	get_node(position_manager_path).center_node = $Window/Margin/VBox/SubViewportContainer/SubViewport/DollyCamera
