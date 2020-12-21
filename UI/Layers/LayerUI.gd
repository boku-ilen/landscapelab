extends PanelContainer


var selected_layer = null # Is layer widget
var filters = {
	"Other": true,
	"Scored": true,
	"Rendered": true
}
var layer_config_window = preload("res://UI/Layers/Misc/LayerConfigurationWindow.tscn")
var current_config_window

onready var new_button = get_node("VBoxContainer/Menu/NewLayer")
onready var delete_button = get_node("VBoxContainer/Menu/DeleteLayer")
onready var filter_button = get_node("VBoxContainer/Menu/Filter")
onready var filter_options = get_node("VBoxContainer/Menu/Filter/FilterOptions")
onready var layer_container = get_node("VBoxContainer/ScrollLayers/LayerContainer")


func _ready():
	_setup_filters()
	
	new_button.connect("pressed", self, "_on_new_layer")
	delete_button.connect("pressed", self, "_delete_layer")
	filter_button.connect("pressed", self, "_open_filter_options")
	filter_options.connect("index_pressed", self, "_alter_filters")
	layer_container.connect("sort_children", self, "_setup_layer_widgets")


func _on_new_layer():
	if current_config_window:
		current_config_window.queue_free()
		
	current_config_window = layer_config_window.instance()
	new_button.add_child(current_config_window)
	current_config_window.popup(new_button.get_global_rect())


func _open_filter_options():
	filter_options.popup(Rect2(rect_global_position, Vector2(20, 10)))


func _alter_filters(idx):
	filters[filter_options.get_item_text(idx)] = !filters[filter_options.get_item_text(idx)]
	filter_options.set_item_checked(idx, !filter_options.is_item_checked(idx))
	
	for child in layer_container.get_children():
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


func _delete_layer():
	if selected_layer != null:
		Layers.remove_layer(selected_layer.name)


func _on_layer_select(event: InputEvent, layer_widget):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if selected_layer != null:
				selected_layer.border.visible = false
			layer_widget.border.visible = true
			selected_layer = layer_widget


func _setup_filters():
	var idx = 0
	for filter in filters:
		filter_options.add_check_item(filter)
		filter_options.set_item_checked(idx, true)
		idx += 1


func _setup_layer_widgets():
	for child in layer_container.get_children():
		if not child.get_signal_list().has("_on_layer_select"):
			child.connect("gui_input", self, "_on_layer_select", [child])

