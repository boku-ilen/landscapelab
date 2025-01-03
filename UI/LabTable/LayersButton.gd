extends Button


# FIXME: make this more responsive to the actual layers instead of hardcoding
func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	$LayersPanel/Content/MapButton.pressed.connect(func(): Layers.layer_definitions["Wind"].z_index = -1)
	$LayersPanel/Content/WindButton.pressed.connect(func(): Layers.layer_definitions["Wind"].z_index = 1)
