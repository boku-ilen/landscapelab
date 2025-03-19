extends Configurator


var layer_composition_renderer = preload("res://Layers/LayerCompositionRenderer.tscn")

@onready var layer_composition_renderers = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready():
	# There may be some rendered layers which were added before this _ready.
	for layer_composition in Layers.get_rendered_layer_compositions():
		add_layer_composition(layer_composition)
	
	# For future layers, use a signal.
	Layers.connect("new_rendered_layer_composition",Callable(self,"add_layer_composition"))
	Layers.connect("removed_rendered_layer_composition",Callable(self,"remove_layer_composition"))


func add_layer_composition(layer_composition: LayerComposition):
	var new_renderer = layer_composition.render_info.renderer.instantiate()
	layer_composition.render_info.renderer_instance = new_renderer
	
	new_renderer.layer_composition = layer_composition
	if layer_composition.name.is_empty():
		layer_composition.name = layer_composition.render_info.get_class_name()
	new_renderer.name = layer_composition.name
	
	layer_composition_renderers.add_composition(new_renderer)


func remove_layer_composition(name_to_remove, _render_info):
	layer_composition_renderers.get_node(name_to_remove).queue_free()
