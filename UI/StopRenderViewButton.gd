extends Button


@export var viewport_path: NodePath
@onready var viewport: Viewport = get_node(viewport_path)


func _ready():
	toggled.connect(disable_rendering)


func disable_rendering(active: bool):
	var update_mode = SubViewport.UPDATE_DISABLED if not active else SubViewport.UPDATE_ALWAYS
	viewport.render_target_update_mode = update_mode
