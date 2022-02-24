extends ConfirmationDialog

var layer: Layer
var specific_layer_ui: SpecificLayerUI

onready var container = get_node("VBoxContainer")
onready var layer_name = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/Name")
onready var layer_color_tag = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/ColorTagMenu")
onready var layer_type = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/TypeChooser")
onready var type_chooser = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/TypeChooser")
onready var min_size = rect_min_size

var RenderTypeObject = {
	"NONE": Layer,
	"BASIC_TERRAIN": Layer,
	"PARTICLES": RasterLayer,
	"OBJECT": FeatureLayer,
	"PATH": FeatureLayer,
	"CONNECTED_OBJECT": FeatureLayer,
	"POLYGON": FeatureLayer,
	"VEGETATION": Layer
}


func _ready():
	connect("confirmed", self, "_on_confirm")
	connect("resized", self, "_on_resize")
	type_chooser.connect("item_selected", self, "_on_type_select")
	
	_add_types()


# Use this function instead of popup to also fill the according layer properties.
# If the layer is not set, the popup will handle the configuration as a new layer.
func layer_popup(rect: Rect2, existing_layer: Layer = null):
	popup(rect)
	layer = existing_layer
	
	if layer != null:
		layer_name.text = layer.name
		layer_type.selected = layer.render_type
		
		# FIXME: this probably should not be done like this anyways so we should fix this
		var type_string: String = layer.RenderType.keys()[layer.render_type]
		type_string = type_string.substr(0, 1) + type_string.substr(1).to_lower()
		specific_layer_ui = load("res://UI/Layers/LayerConfiguration/SpecificLayerUI/%sLayer.tscn" % type_string).instance()
		container.add_child(specific_layer_ui)
		container.move_child(specific_layer_ui, 1)


func _on_confirm():
	var is_new: bool = false
	var current_type = layer_type.get_item_metadata(layer_type.get_selected_id())
	
	if layer == null:
		layer = RenderTypeObject[current_type].new()
		is_new = true
	
	layer.name = layer_name.text
	layer.render_type = Layer.RenderType[current_type]
	layer.color_tag = layer_color_tag.current_color
	specific_layer_ui.assign_specific_layer_info(layer)
	
	if not layer.is_valid():
		logger.error("Confirmation would've created invalid layer with name: %s and type: %s. Aborting"
				% [layer.name, current_type])
		# TODO: Should we give an error in the UI here too, or did this definitely already happen
		#  in assign_specific_layer_info?
		return
	
	if is_new:
		Layers.add_layer(layer)
	else:
		layer.emit_signal("layer_changed")
	
	hide()


func resize(add: Vector2):
	rect_min_size = min_size + add
	rect_size = rect_min_size


func _on_resize():
	container.rect_size.x = rect_size.x - 75


func _add_types():
	var idx = 0
	for type in Layer.RenderType:
		type_chooser.add_item(type)
		type_chooser.set_item_metadata(idx, type)
		idx += 1


# TODO: This shouldnt be all upercase anyways, maybe move this functionality
func _on_type_select(idx: int):
	var type: String = type_chooser.get_item_text(idx)
	type = type.substr(0, 1) + type.substr(1).to_lower()
	
	if specific_layer_ui != null:
		container.remove_child(specific_layer_ui)
	
	specific_layer_ui = load("res://UI/Layers/LayerConfiguration/SpecificLayerUI/%sLayer.tscn" % type).instance()
	container.add_child(specific_layer_ui)
	container.move_child(specific_layer_ui, 1)
	
	resize(Vector2(0, specific_layer_ui.rect_size.y))
