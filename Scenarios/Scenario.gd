extends Node
class_name Scenario


var visible_layer_names = []


func add_visible_layer_name(layer_name: String):
	visible_layer_names.append(layer_name)


func activate():
	for layer_name in Layers.layer_compositions.keys():
		if layer_name in visible_layer_names:
			Layers.get_layer_composition(layer_name).is_visible = true
		else:
			Layers.get_layer_composition(layer_name).is_visible = false
