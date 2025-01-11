extends Button


@export var rendering_subviewport: SubViewportContainer


# FIXME: make this more responsive to the actual layers instead of hardcoding
func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	$LayersPanel/Content/MapButton.pressed.connect(func(): 
			Layers.layer_definitions["Wind"].z_index = -1
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_PASS))
	$LayersPanel/Content/WindButton.pressed.connect(func():
			Layers.layer_definitions["Wind"].z_index = 1
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_IGNORE))
