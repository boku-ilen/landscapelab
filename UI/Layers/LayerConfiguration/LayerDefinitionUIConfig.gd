extends Configurator

@export var position_manager_path: NodePath

var layer_widget = preload("res://UI/Layers/LayerConfiguration/LayerDefinitionWidget.tscn")

@export var layer_definition_container: VBoxContainer
@onready var position_manager = get_node(position_manager_path)


func _ready():
	# if the UI was instanced later than the world, we need to check for already instanced layers
	for layer_definition in Layers.layer_definitions.values():
		add_layer_definition(layer_definition)
		
	Layers.new_layer_definition.connect(add_layer_definition)


func add_layer_definition(layer_definition: LayerDefinition):
	var layer_widget = layer_widget.instantiate()
	layer_widget.layer_definition = layer_definition
	
	if layer_widget.name.is_empty():
		layer_widget.name = layer_definition.render_info.get_class_name()
	
	layer_widget.name = layer_definition.name
	layer_definition_container.add_child(layer_widget)
	
	return true
