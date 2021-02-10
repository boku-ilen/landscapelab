extends Resource
class_name VegetationLayerComposition


export(Array, Resource) var layers


func get_renderers(root_name="VegetationRenderers"):
	var root = Spatial.new()
	root.name = root_name
	
	for layer in layers:
		root.add_child(layer.get_renderer())
	
	return root
