extends Configurator

@onready var list: ItemList = get_parent().get_node("ItemList")


func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer in Layers.geo_layers["rasters"]:
		add_geo_layer(Layers.geo_layers["rasters"][layer], true)
	
	for layer in Layers.geo_layers["features"]:
		add_geo_layer(Layers.geo_layers["features"][layer], false)
	
	Layers.connect("new_geo_layer",Callable(self,"add_geo_layer"))
	list.z_index_changed.emit(list.get_items())


func add_geo_layer(geo_layer: Resource, is_raster: bool):
	var new_layer_idx = list.add_item(geo_layer.resource_name)
	list.set_item_metadata(new_layer_idx, geo_layer)


func remove_layer(layer_name: String):
	#layer_container.get_node(layer_name).queue_free()
	pass
