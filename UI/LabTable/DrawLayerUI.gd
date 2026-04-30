extends VBoxContainer
class_name DrawLayerUI

var layers : Array[DrawLayerMenuItem]
var id_counter = 0

@export var drawing_coordinator: DrawingCoordinator
@export var dropdown_controller: DrawLayerDropdownMenu

var layers_free: Dictionary[String, bool]

func _ready() -> void:
	layers_free = {}
	for layer_name in drawing_coordinator.layers.keys():
		layers_free[layer_name] = true
	add_layer()
	$AddLayer.pressed.connect(func (): add_layer())
	
func add_layer():
	dropdown_controller.destroy_menu()
	var free_layers = drawing_coordinator.layers.keys().filter(func (e): return layers_free[e])
	if len(free_layers) == 0:
		return
	var next_free = free_layers[0]
	var new_layer = DrawLayerMenuItem.new(next_free)
	add_child(new_layer)
	id_counter += 1
	new_layer.layer_id = id_counter
	new_layer.register_drop_action(drop_by_id)
	layers.append(new_layer)
	layers_free[next_free] = false
	if len(free_layers) <= 1:
		$AddLayer.visible = false

func open_dropdown(calling_layer_id):
	logger.info(str(calling_layer_id))
	var free_keys = drawing_coordinator.layers.keys().filter(func (e): return layers_free[e])
	for l in layers:
		if l.layer_id == calling_layer_id:
			free_keys.append(l.layer_name)
	dropdown_controller.create_menu(free_keys, func (choice): handle_dropdown_choice(calling_layer_id, choice))

func handle_dropdown_choice(layer_id, choice):
	for layer in layers:
		if layer.layer_id == layer_id:
			var old_layer = layer.layer_name
			layers_free[old_layer] = true
			layer.layer_name = choice
			layers_free[choice] = false
	dropdown_controller.destroy_menu()
	
	
func drop_by_id(id):
	dropdown_controller.destroy_menu()
	var removed_index = -1
	for i in range(len(layers)):
		if layers[i].layer_id == id:
			layers_free[layers[i].layer_name] = true
			layers[i].queue_free()

			removed_index = i
			break
	layers.remove_at(removed_index)
	$AddLayer.visible = true

func get_sample_points():
	var pts = []
	for l in layers:
		pts.append(l.get_swatch_position())
	return pts
func get_layer_names():
	var names = []
	for l in layers:
		names.append(l.layer_name)
	return names
