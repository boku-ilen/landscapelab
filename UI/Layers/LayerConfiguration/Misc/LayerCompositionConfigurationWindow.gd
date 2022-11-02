extends ConfirmationDialog

var layer_composition: LayerComposition
var specific_layer_composition_ui: SpecificLayerCompositionUI

@onready var container = get_node("VBoxContainer")
@onready var layer_composition_name = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/Name")
@onready var layer_composition_color_tag = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/ColorTagMenu")
@onready var layer_composition_type = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/TypeChooser")
@onready var type_chooser = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/TypeChooser")

var RenderTypeObject = {
	"NONE": LayerComposition,
	"BASIC_TERRAIN": LayerComposition,
	"REALISTIC_TERRAIN": LayerComposition,
	"PARTICLES": LayerComposition,
	"OBJECT": LayerComposition,
	"PATH": LayerComposition,
	"CONNECTED_OBJECT": LayerComposition,
	"POLYGON": LayerComposition,
	"VEGETATION": LayerComposition,
	"TWODIMENSIONAL": LayerComposition
}


func _ready():
	connect("confirmed",Callable(self,"_on_confirm"))
	type_chooser.connect("item_selected",Callable(self,"_on_type_select"))
	
	_add_types()


# Use this function instead of popup to also fill the according layer properties.
# If the layer is not set, the popup will handle the configuration as a new layer.
func layer_popup(min_size: Vector2, existing_layer_composition: LayerComposition = null):
	popup_centered(min_size)
	layer_composition = existing_layer_composition
	
	if layer_composition != null:
		layer_composition_name.text = layer_composition.name
		layer_composition_type.selected = layer_composition.render_type
		
		# FIXME: this probably should not be done like this anyways so we should fix this
		var type_string: String = LayerComposition.RenderType.keys()[layer_composition.render_type]
		type_string = type_string.substr(0, 1) + type_string.substr(1).to_lower()
		_add_specific_layer_conf(type_string)


func _on_confirm():
	var is_new: bool = false
	var current_type = layer_composition_type.get_item_metadata(layer_composition_type.get_selected_id())
	
	if layer_composition == null:
		layer_composition = RenderTypeObject[current_type].new()
		is_new = true
	
	layer_composition.name = layer_composition_name.text
	layer_composition.render_type = LayerComposition.RenderType[current_type]
	layer_composition.color_tag = layer_composition_color_tag.current_color
	specific_layer_composition_ui.assign_specific_layer_info(layer_composition)
	
	if not layer_composition.is_valid():
		logger.error("Confirmation would've created invalid layer with name: %s and type: %s. Aborting"
				% [layer_composition.name, current_type], "LAYERCONFIG")
		# TODO: Should we give an error in the UI here too, or did this definitely already happen
		#  in assign_specific_layer_info?
		return
	
	if is_new:
		LayerComposition.add_layer(layer_composition)
	else:
		layer_composition.emit_signal("layer_changed")
		layer_composition.emit_signal("refresh_view")
	
	hide()

# FIXME: Is this still necessary?
#func resize(add: Vector2):
#	minimum_size.y = min_size.y + add.y
#	minimum_size.x = max(add.x, min_size.x) 
#	size = minimum_size


func _add_types():
	var idx = 0
	for type in LayerComposition.RenderType:
		type_chooser.add_item(type)
		type_chooser.set_item_metadata(idx, type)
		idx += 1


# TODO: This shouldnt be all upercase anyways, maybe move this functionality
func _on_type_select(idx: int):
	var type: String = type_chooser.get_item_text(idx)
	type = type.substr(0, 1) + type.substr(1).to_lower()
	
	if specific_layer_composition_ui != null:
		container.remove_child(specific_layer_composition_ui)
	
	_add_specific_layer_conf(type)


func _add_specific_layer_conf(type_string: String):
	specific_layer_composition_ui = load(
			"res://UI/Layers/LayerConfiguration/SpecificLayerCompositionUI/%sLayer.tscn" 
			% type_string).instantiate()
	
	if layer_composition: specific_layer_composition_ui.init(layer_composition)
	
	container.add_child(specific_layer_composition_ui)
	container.move_child(specific_layer_composition_ui, 1)
	
	specific_layer_composition_ui.connect("new_size",Callable(self,"resize"))
