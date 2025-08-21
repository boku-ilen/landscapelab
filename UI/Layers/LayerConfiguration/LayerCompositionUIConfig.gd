extends Configurator

@export var position_manager_path: NodePath

var layer_widget_res = preload("res://UI/Layers/LayerConfiguration/LayerCompositionWidget.tscn")
var group_widget_res = preload("res://UI/Layers/LayerConfiguration/LayersGroupWidget.tscn")

@onready var layer_composition_container = get_parent().get_node("VBoxContainer/ScrollLayers/LayerContainer")
@onready var position_manager = get_node(position_manager_path)

var layer_composition_widgets = {}
var layer_group_widgets = {}

func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer_composition in Layers.layer_compositions.values():
		add_layer_composition_widget(layer_composition)
		
	Layers.new_layer_composition.connect(add_layer_composition_widget)
	Layers.removed_layer_composition.connect(remove_layer_composition_widget)
	Layers.new_layer_group.connect(add_layer_group_widget)


func add_layer_composition_widget(layer_composition: LayerComposition):
	var new_layer_composition = layer_widget_res.instantiate()
	new_layer_composition.layer_composition = layer_composition
	if layer_composition.name.is_empty():
		layer_composition.name = layer_composition.render_info.get_class_name()
	
	new_layer_composition.name = layer_composition.name
	# hocus pocus; i was here 20/08/2025
	# Add to group or root depending on whether group is set
	if layer_composition.group and layer_composition.group.name in layer_group_widgets:
		layer_group_widgets[layer_composition.group.name].layers_container.add_child(new_layer_composition)
	else:
		layer_composition_container.add_child(new_layer_composition)
	
	new_layer_composition.translate_to_layer.connect(position_manager.set_offset)
	layer_composition_widgets[layer_composition.name] = new_layer_composition


func remove_layer_composition_widget(layer_composition_name: String):
	layer_composition_widgets[layer_composition_name].queue_free()


func add_layer_group_widget(layer_group: LayerResourceGroup):
	# Could be for layerdefinitions
	if layer_group.layer_resources.container.any(func(lr): return not lr is LayerComposition):
		return
	
	var new_layer_group = group_widget_res.instantiate()
	new_layer_group.layer_resource_group = layer_group
	new_layer_group.name = layer_group.name
	layer_composition_container.add_child(new_layer_group)
	
	# Since deserialization happens recursively, children are loaded before the container
	for layer_res in layer_group.layer_resources.container:
		if not new_layer_group.has_node(layer_res.name) \
		and layer_composition_container.has_node(layer_res.name):
			var layer_res_ui: Control
			if layer_res is LayerComposition:
				layer_res_ui = layer_composition_widgets[layer_res.name]
			elif layer_res is LayerResourceGroup:
				layer_res_ui = layer_group_widgets[layer_res.name]
				
			layer_composition_container.remove_child(layer_res_ui)
			new_layer_group.layers_container.add_child(layer_res_ui)
	
	layer_group_widgets[layer_group.name] = new_layer_group


func remove_layer_group_widget(layer_group_name: String):
	layer_group_widgets[layer_group_name].queue_free()
