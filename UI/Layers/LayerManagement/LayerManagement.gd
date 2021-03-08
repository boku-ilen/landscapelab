extends Node


export var layer_ui_path: NodePath

onready var layer_ui = get_node(layer_ui_path)

var current_layer_management_ui
var pc_player: AbstractPlayer
var pos_manager: PositionManager


func _ready():
	layer_ui.connect("new_layer_selected", self, "_new_layer_selected")


func _new_layer_selected(layer):
	var type_str = layer.RenderType.keys()[layer.render_type]
	type_str = type_str.substr(0, 1).to_upper() + type_str.substr(1).to_lower()
	var ui_path = "res://UI/Layers/LayerManagement/%sLayerManagement.tscn" % type_str
	
	var file2check = File.new()
	if file2check.file_exists(ui_path):
		current_layer_management_ui = load(ui_path).instance()
		current_layer_management_ui.init(pc_player, layer)
		add_child(current_layer_management_ui)
	else: 
		if current_layer_management_ui != null:
			current_layer_management_ui.queue_free()
