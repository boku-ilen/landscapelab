extends PanelContainer


signal new_layer_selected(layer)

var selected_layer_composition = null # Is layer widget
var filters = {
	"Other": true,
	"Scored": true,
	"Rendered": true
}
var layer_composition_config_window = preload("res://UI/Layers/LayerConfiguration/LayerCompositionConfigurationWindow.tscn")
var current_config_window

@onready var new_button = get_node("VBoxContainer/Menu/NewLayer")
@onready var delete_button = $VBoxContainer/Menu/DeleteLayer
@onready var filter_button = get_node("VBoxContainer/Menu/Filter")
@onready var filter_options = get_node("VBoxContainer/Menu/Filter/FilterOptions")
@onready var layer_composition_container = get_node("VBoxContainer/ScrollLayers/LayerContainer")


func _ready():
	_setup_filters()
	
	new_button.connect("pressed",Callable(self,"_on_new_layer_composition"))
	delete_button.connect("pressed",Callable(self,"_delete_layer_composition"))
	filter_button.connect("pressed",Callable(self,"_open_filter_options"))
	filter_options.connect("index_pressed",Callable(self,"_alter_filters"))
	layer_composition_container.connect("sort_children",Callable(self,"_setup_layer_composition_widgets"))


func _on_new_layer_composition():
	if current_config_window:
		current_config_window.queue_free()
		
	current_config_window = layer_composition_config_window.instantiate()
	new_button.add_child(current_config_window)
	current_config_window.popup_centered()


func _open_filter_options():
	filter_options.popup(Rect2(global_position, Vector2(20, 10)))


func _alter_filters(idx):
	filters[filter_options.get_item_text(idx)] = !filters[filter_options.get_item_text(idx)]
	filter_options.set_item_checked(idx, !filter_options.is_item_checked(idx))
	
	for child in layer_composition_container.get_children():
		var is_rendered = Layers.is_layer_rendered(child.layer)
		var is_scored = child.layer.is_scored
		var is_visible = false
		if is_scored and filters["Scored"] == true:
			is_visible = true
		if is_rendered and filters["Rendered"] == true:
			is_visible = true
		if !is_scored and !is_rendered and filters["Other"] == true:
			is_visible = true
		
		child.visible = is_visible


func _delete_layer_composition():
	if selected_layer_composition != null:
		Layers.remove_layer_composition(selected_layer_composition.layer_composition.name)


func _on_layer_select(event: InputEvent, layer_composition_widget):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:# and event.pressed:
			selected_layer_composition = layer_composition_widget
			emit_signal("new_layer_selected", layer_composition_widget.layer_composition)


func _setup_filters():
	var idx = 0
	for filter in filters:
		filter_options.add_check_item(filter)
		filter_options.set_item_checked(idx, true)
		idx += 1


func _setup_layer_composition_widgets():
	for child in layer_composition_container.get_children():
		if not child.is_connected("gui_input",Callable(self,"_on_layer_select")):
			child.connect("gui_input",Callable(self,"_on_layer_select").bind(child))

