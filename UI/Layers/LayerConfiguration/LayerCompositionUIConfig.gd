extends Configurator

@export var position_manager_path: NodePath

var layer_widget = preload("res://UI/Layers/LayerConfiguration/LayerCompositionWidget.tscn")

@onready var layer_composition_container = get_parent().get_node("VBoxContainer/ScrollLayers/LayerContainer")
@onready var position_manager = get_node(position_manager_path)


func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer_composition in Layers.layer_compositions.values():
		add_layer_composition(layer_composition)
		
	Layers.connect("new_layer_composition",Callable(self,"add_layer_composition"))
	Layers.connect("removed_layer_composition",Callable(self,"remove_layer_composition"))


func add_layer_composition(layer_composition: LayerComposition):
	var new_layer_composition = layer_widget.instantiate()
	new_layer_composition.layer_composition = layer_composition
	if layer_composition.name.is_empty():
		layer_composition.name = layer_composition.render_info.get_class_name()
	
	new_layer_composition.name = layer_composition.name
	# hocus pocus
	layer_composition_container.add_child(new_layer_composition)
	
	new_layer_composition.connect("translate_to_layer",Callable(position_manager,"set_offset"))
	
	return true


func remove_layer_composition(layer_composition_name: String):
	layer_composition_container.get_node(layer_composition_name).queue_free()
	
	return true
