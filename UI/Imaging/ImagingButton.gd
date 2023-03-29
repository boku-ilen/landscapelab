extends AutoIconButton

@export var action_handler_3d_path: NodePath


func _ready():
	$Window.action_handlers = [get_node(action_handler_3d_path)]
	toggled.connect($Window.set_visible)
