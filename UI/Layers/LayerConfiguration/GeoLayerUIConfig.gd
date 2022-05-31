extends Configurator

onready var tree: Tree = get_parent().get_node("Tree")
onready var root = tree.create_item()


func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer in Layers.geo_layers["rasters"]:
		add_geo_layer(Layers.geo_layers["rasters"][layer], true)
	
	for layer in Layers.geo_layers["features"]:
		add_geo_layer(Layers.geo_layers["features"][layer], false)
		
	Layers.connect("new_geo_layer", self, "add_geo_layer")


func add_geo_layer(geo_layer: Resource, is_raster: bool):
	var new_layer = tree.create_item(root)
	new_layer.set_metadata(0, geo_layer)
	new_layer.set_text(0, geo_layer.resource_name)


func remove_layer(layer_name: String):
	#layer_container.get_node(layer_name).queue_free()
	pass
