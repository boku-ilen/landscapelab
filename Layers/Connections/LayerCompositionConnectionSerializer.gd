extends Object
class_name LayerCompositionConnectionSerializer



static func deserialize(type: String, source_string: String, target_string: String):
	var test = load("res://Layers/Connections/%s.gd" % [type]).new(
		Layers.layer_compositions[source_string], 
		Layers.layer_compositions[target_string]
	)
