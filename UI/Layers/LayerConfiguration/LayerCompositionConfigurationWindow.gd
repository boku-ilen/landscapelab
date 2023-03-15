extends ConfirmationDialog

var layer_composition
# Name to node
var specific_layer_composition_ui: Dictionary = {}

# Each property in a layercomposition should get a generic form
# to fill the corresponding value; e.g. Geo<Raster/Feature>Layer => GeodataChooser
# On confirm, each object needs to return a value => Godot does not offer a generic
# get value so we define it ourselves
class ui_wrapper:
	func _init(control_func, val_func):
		get_control = control_func
		get_value = val_func
	
	var get_control: Callable
	var get_value: Callable

var property_to_ui = {
	"GeoRasterLayer": ui_wrapper.new(
		func():
			var gdc = preload("res://UI/Layers/LayerConfiguration/Misc/GeodataChooser.tscn").instantiate()
			gdc.show_feature_layer = false
			return gdc,
		func(x): return x.get_full_dataset_string()
	),
	"GeoFeatureLayer": ui_wrapper.new(
		func():
			var gdc = preload("res://UI/Layers/LayerConfiguration/Misc/GeodataChooser.tscn").instantiate()
			gdc.show_raster_layers = false
			return gdc,
		func(x): return x.get_full_dataset_string()
	),
	"Color": ui_wrapper.new(
		func(): return preload("res://UI/Layers/LayerConfiguration/Misc/ColorButton.tscn").instantiate(),
		func(x): return x.get_color()
	),
	TYPE_DICTIONARY: ui_wrapper.new(
		func(): return preload("res://UI/Layers/LayerConfiguration/Misc/DictionaryUIReflection.tscn").instantiate(),
		func(x): return x.get_values()
	),
	TYPE_STRING: ui_wrapper.new(
		func(): return LineEdit.new(),
		func(x: LineEdit): return x.get_text()
	),
	TYPE_STRING_NAME: ui_wrapper.new(
		func(): return LineEdit.new(),
		func(x: LineEdit): return x.get_text()
	),
	TYPE_BOOL: ui_wrapper.new(
		func(): return CheckBox.new(),
		func(x: CheckBox): return x.is_pressed()
	),
	TYPE_FLOAT: ui_wrapper.new(
		func(): return SpinBox.new(),
		func(x: SpinBox): return x.get_value()
	),
}

@onready var layer_composition_name = $VBoxContainer/GridContainer/Name
@onready var layer_composition_color_tag = $VBoxContainer/GridContainer/ColorTagMenu
@onready var type_chooser = $VBoxContainer/GridContainer/TypeChooser


func _ready():
	connect("confirmed",Callable(self,"_on_confirm"))
	type_chooser.connect("item_selected",Callable(self,"_on_type_select"))
	
	_add_layer_composition_types()


# Use this function instead of popup to also fill the according layer properties.
# If the layer is not set, the popup will handle the configuration as a new layer.
func layer_popup(min_size: Vector2, existing_layer_composition: LayerComposition = null):
	layer_composition = existing_layer_composition
	
	if layer_composition != null:
		layer_composition_name.text = layer_composition.name
		
		# Find the type string corresponding to this layer's render info
		var type_string: String
		var type_id := 0
		
		for render_info_name in LayerComposition.RENDER_INFOS.keys():
			if is_instance_of(layer_composition.render_info, LayerComposition.RENDER_INFOS[render_info_name]):
				type_string = render_info_name
			
			type_id += 1
		
		# Note that this requires the type_chooser to be filled in the same
		# order as LayerComposition.RENDER_INFOS
		type_chooser.selected = type_id
		
		_add_specific_layer_conf(type_string)
		
		# Fill attributes
		for property in layer_composition.render_info.get_property_list():
			if specific_layer_composition_ui.has(property["name"]):
				var node = specific_layer_composition_ui[property["name"]]
				
				# FIXME: Doesn't work for some non-stringable types (especially Layers)
				# We'll need to handle this more intelligently based on property["class_name"]
				node.get_node("Data").text = var_to_str(
					layer_composition.render_info.get(property["name"]))
	
	popup_centered(min_size)


func _on_confirm():
	var is_new: bool = false
	var current_type = type_chooser.get_item_metadata(type_chooser.get_selected_id())
	
	if layer_composition == null:
		layer_composition = LayerComposition.new()
		is_new = true
	
	# "Fake" an *.ll file
	layer_composition = LayerCompositionSerializer.deserialize(
		"",
		layer_composition_name.text,
		current_type,
		_build_attributes_dictionary(),
		layer_composition
	)
	
	layer_composition.color_tag = layer_composition_color_tag.current_color
	
	if not layer_composition.is_valid():
		logger.error("Confirmation would've created invalid layer with name: %s and type: %s. Aborting"
				% [layer_composition.name, current_type])
		# TODO: Should we give an error in the UI here too, or did this definitely already happen
		#  in assign_specific_layer_info?
		return
	
	if is_new:
		Layers.add_layer_composition(layer_composition)
	else:
		layer_composition.emit_signal("layer_changed")
		layer_composition.emit_signal("refresh_view")
	
	# FIXME: Make the LayerComposition renderer do a full load
	
	hide()


# Build an attribute-dictionary like in the ".ll" config out of the ui
func _build_attributes_dictionary():
	var attributes = {}
	for element_name in specific_layer_composition_ui:
		if element_name.begins_with("object_"):
			var ui_element = specific_layer_composition_ui[element_name]
			var type_name = element_name.trim_prefix("object_")
			attributes[type_name] = property_to_ui[ui_element.get_meta(
				"represents_type")].get_value.call(ui_element)
	
	return attributes


func _add_layer_composition_types():
	var idx = 0
	for type in LayerComposition.RENDER_INFOS.keys():
		type_chooser.add_item(type)
		type_chooser.set_item_metadata(idx, type)
		idx += 1


func _on_type_select(idx: int):
	var type: String = type_chooser.get_item_text(idx)
	
	# First remove all configuration from possible previous other types
	_remove_specific_layer_conf()
	_add_specific_layer_conf(type)


func _remove_specific_layer_conf():
	for element in specific_layer_composition_ui.values():
		$VBoxContainer/GridContainer.remove_child(element)
		element.queue_free()
	specific_layer_composition_ui.clear()


func _add_specific_layer_conf(type_string: String):
	var render_info = LayerComposition.RENDER_INFOS[type_string].new()
	
	# Create list of basic Object properties so we can ignore those later
	var base_property_names = []
	var base_render_info = LayerComposition.RenderInfo.new()
	for property in base_render_info.get_property_list():
		base_property_names.append(property["name"])
	
	for property in render_info.get_property_list():
		# Ignore basic Object properties
		if property["name"] in base_property_names: continue
		
		# Generically find an ui object that handles the needs of the type
		# e.g. geodatachooser for Geo<Raster/Feature>Layer
		var ui_object: Control
		var type = property["type"]
		if property["type"] == TYPE_OBJECT:
			type = property["class_name"]
			ui_object = property_to_ui[property["class_name"]].get_control.call()
		else:
			ui_object = property_to_ui[property["type"]].get_control.call()
		
		ui_object.name = "object_{}".format([property["name"]], "{}")
		# In order to get a value from property to ui mapping we need
		# access to the type/class_name in func _get_specific_attributes()
		ui_object.set_meta("represents_type", type)
		
		# Add a label in the ui
		var label = Label.new()
		label.text = "{}:".format([property["name"]], "{}")
		label.name =  "label_{}".format([property["name"]], "{}")
		
		$VBoxContainer/GridContainer.add_child(label)
		$VBoxContainer/GridContainer.add_child(ui_object)
		
		specific_layer_composition_ui[label.name] = label
		specific_layer_composition_ui[ui_object.name] = ui_object
