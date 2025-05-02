extends Button


@export var rendering_subviewport: SubViewportContainer

enum PROJECT {
	BIOPV,
	WIMBY,
	NONE
}
var current_project = PROJECT.WIMBY


# FIXME: make this more responsive to the actual layers instead of hardcoding
func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	match current_project:
		PROJECT.BIOPV: biopv_setup()
		PROJECT.WIMBY: wimby_setup()


func wimby_setup():
	$LayersPanel/Content/SunButton.set_visible(false)
	
	var wind_potential = Layers.layer_definitions["WindPotential"]
	var ecology = Layers.layer_definitions["BirdEcology"]
	
	$LayersPanel/Content/MapButton.pressed.connect(func(): 
		wind_potential.z_index = -1
		ecology.z_index = -1
		$ColorRampSymbology.visible = false)
	$LayersPanel/Content/WindButton.pressed.connect(func(): 
		wind_potential.z_index = 1
		ecology.z_index = -1
		$ColorRampSymbology.ticks_at = Array([0., 0.5, 1.], TYPE_FLOAT, "", null)
		$ColorRampSymbology.ticks_val = Array([11., 7., 3.], TYPE_FLOAT,  "", null)
		$ColorRampSymbology.gradient = wind_potential.render_info.gradient
		$ColorRampSymbology.visible = true)
	$LayersPanel/Content/BioDivButton.pressed.connect(func():
		wind_potential.z_index = -1
		ecology.z_index = 1
		$ColorRampSymbology.ticks_at = Array([0., 0.5, 1.], TYPE_FLOAT, "", null)
		$ColorRampSymbology.ticks_val = Array([1., .5, .0], TYPE_FLOAT,  "", null)
		$ColorRampSymbology.gradient = ecology.render_info.gradient
		$ColorRampSymbology.visible = true)


func biopv_setup():
	$LayersPanel/Content/WindButton.set_visible(false)
	
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
