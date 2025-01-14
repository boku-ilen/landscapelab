extends Button


@export var rendering_subviewport: SubViewportContainer


# FIXME: make this more responsive to the actual layers instead of hardcoding
func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	
	$LayersPanel/Content/MapButton.pressed.connect(func(): 
			Layers.layer_definitions["Wind"].z_index = -1
			$ColorRampSymbology.visible = false
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_PASS))
			
	$LayersPanel/Content/WindButton.pressed.connect(func():
			var wind_layer = Layers.layer_definitions["Wind"]
			wind_layer.z_index = 1
			$ColorRampSymbology.gradient = wind_layer.render_info.gradient
			$ColorRampSymbology.ticks_from_relative_values([0, 0.25, 0.5, 0.75, 1.], wind_layer.render_info.min_val, wind_layer.render_info.max_val)
			$ColorRampSymbology.visible = true
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_IGNORE))
