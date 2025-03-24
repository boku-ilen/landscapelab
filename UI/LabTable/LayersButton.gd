extends Button


@export var rendering_subviewport: SubViewportContainer


# FIXME: make this more responsive to the actual layers instead of hardcoding
func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	var energy_potential = Layers.layer_definitions["EnergyPotential"]
	var conflict_areas = Layers.layer_definitions["ConflictAreas"]
	
	$LayersPanel/Content/MapButton.pressed.connect(func(): 
			energy_potential.z_index = -1
			conflict_areas.z_index = -1
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_PASS))
			
	$LayersPanel/Content/SunButton.pressed.connect(func():
			energy_potential.z_index = 1
			conflict_areas.z_index = -1
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_IGNORE))
	
	$LayersPanel/Content/BioDivButton.pressed.connect(func():
			conflict_areas.z_index = 1
			energy_potential.z_index = -1
			rendering_subviewport.set_mouse_filter(MouseFilter.MOUSE_FILTER_IGNORE))
