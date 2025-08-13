extends Button


@export var rendering_subviewport: SubViewportContainer

signal new_active(layer_def: LayerDefinition)


func _ready() -> void:
	pressed.connect(func(): $LayersPanel.visible = !$LayersPanel.visible)
	Layers.new_layer_definition.connect(_setup_layer_def)
	for layer_def in Layers.layer_definitions.values():
		_setup_layer_def(layer_def)


func _setup_layer_def(layer_def: LayerDefinition):
	if not layer_def.ui_info.as_table_button:
		return
	
	var button = Button.new()
	# TODO: is this still necessary?
	button.set_script(load("res://UI/LabTable/TableButton.gd"))
	button.icon = layer_def.ui_info.icon
	button.toggle_mode = true
	button.toggled.connect(func(pressed: bool):
		_toggle_z_index(layer_def, pressed)
		if pressed:
			new_active.emit(layer_def)
	)
	new_active.connect(func(new_active: LayerDefinition): 
		if layer_def != new_active:
			button.set_pressed(false)
		else:
			_set_color_ramp(layer_def)
	)
	
	$LayersPanel/Content.add_child(button)


func _toggle_z_index(layer_def: LayerDefinition, active: bool):
	var toggle_indices = layer_def.ui_info.toggle_z_indices
	layer_def.render_info.z_index = toggle_indices[int(active)]


func _set_color_ramp(layer_def: LayerDefinition):
	var test = layer_def.render_info
	if layer_def.render_info.gradient == null:
		$ColorRampSymbology.visible = false
		return
	
	$ColorRampSymbology.visible = true
	$ColorRampSymbology.ticks_at = Array(layer_def.ui_info.ticks_at, TYPE_FLOAT, "", null)
	$ColorRampSymbology.ticks_val = Array(layer_def.ui_info.ticks_val, TYPE_FLOAT,  "", null)
	$ColorRampSymbology.gradient = layer_def.render_info.gradient
