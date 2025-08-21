extends Button


@export var rendering_subviewport: SubViewportContainer

signal new_active(layer_def: LayerDefinition)

var layer_def_uis := {}
var layer_group_uis := {}


func _ready() -> void:
	toggled.connect($LayersPanel.set_visible)
	Layers.new_layer_definition.connect(_setup_layer_def)
	Layers.new_layer_group.connect(_setup_layer_group)
	for layer_def in Layers.layer_definitions.values():
		_setup_layer_def(layer_def)
	for layer_group in Layers.layer_groups.values():
		_setup_layer_group(layer_group)


func _setup_layer_def(layer_def: LayerDefinition):
	if not layer_def.ui_info.as_table_button:
		return
	
	var button = preload("res://UI/LabTable/TableToggleButton.tscn").instantiate()
	button.icon = layer_def.ui_info.icon
	button.name = layer_def.name
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
	
	$LayersPanel/HBoxContainer/Content.add_child(button)
	layer_def_uis[layer_def.name] = button


func _setup_layer_group(layer_group: LayerResourceGroup):
	# Could be for LayerComps
	if layer_group.layer_resources.container.any(func(lr): return not lr is LayerDefinition):
		return
		
	var group_ui = preload("res://UI/LabTable/LayerDefinitionGroup.tscn").instantiate()
	if layer_group.icon: 
		group_ui.get_node("Control/TextureRect").texture = layer_group.icon
	
	$LayersPanel/HBoxContainer/Content.add_child(group_ui)
	
	# Since deserialization happens recursively, children are loaded before the container
	for layer_res in layer_group.layer_resources.container:
		if not group_ui.get_node("Margin/HBox").has_node(layer_res.name) \
		and $LayersPanel/HBoxContainer/Content.has_node(layer_res.name):
			var layer_res_ui: Control
			if layer_res is LayerDefinition:
				layer_res_ui = layer_def_uis[layer_res.name]
			elif layer_res is LayerResourceGroup:
				layer_res_ui = layer_group_uis[layer_res.name]
				
			$LayersPanel/HBoxContainer/Content.remove_child(layer_res_ui)
			group_ui.get_node("Margin/HBox").add_child(layer_res_ui)
	
	layer_group_uis[layer_group.name] = group_ui


func _toggle_z_index(layer_def: LayerDefinition, active: bool):
	var toggle_indices = layer_def.ui_info.toggle_z_indices
	layer_def.render_info.z_index = toggle_indices[int(active)]


func _set_color_ramp(layer_def: LayerDefinition):
	var color_ramp = $LayersPanel/HBoxContainer/ColorRampSymbology
	if layer_def.render_info.gradient == null:
		color_ramp.visible = false
		return
	
	color_ramp.visible = true
	color_ramp.ticks_at = Array(layer_def.ui_info.ticks_at, TYPE_FLOAT, "", null)
	color_ramp.ticks_val = Array(layer_def.ui_info.ticks_val, TYPE_FLOAT,  "", null)
	color_ramp.gradient = layer_def.render_info.gradient
