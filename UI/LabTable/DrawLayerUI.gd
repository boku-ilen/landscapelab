extends VBoxContainer
class_name DrawLayerUI

var layers : Array[DrawLayerMenuItem]
var id_counter = 0
func _ready() -> void:
	add_layer()
	$AddLayer.pressed.connect(add_layer)
	
func add_layer():
	var new_layer = DrawLayerMenuItem.new()
	add_child(new_layer)
	id_counter += 1
	new_layer.layer_id = id_counter
	new_layer.register_drop_action(drop_by_id)
	layers.append(new_layer)
	
func drop_by_id(id):
	var removed_index = -1
	for i in range(len(layers)):
		if layers[i].layer_id == id:
			layers[i].queue_free()

			removed_index = i
			break
	
	layers.remove_at(removed_index)

func get_sample_points():
	var pts = []
	for l in layers:
		pts.append(l.get_swatch_position())
	return pts
