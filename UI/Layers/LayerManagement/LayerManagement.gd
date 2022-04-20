extends Node


export var layer_ui_path: NodePath
export var pos_manager_path: NodePath

onready var layer_ui = get_node(layer_ui_path)

var current_layer_management_ui
var pc_player: AbstractPlayer
var pos_manager: PositionManager


func _ready():
	layer_ui.connect("new_layer_selected", self, "_new_layer_selected")
	pos_manager = get_node(pos_manager_path)
	pos_manager.connect("new_center_node", self, "_on_new_center_node")


func _on_new_center_node(new_center_node):
	pc_player = new_center_node
	
	if current_layer_management_ui:
		current_layer_management_ui.set_player(new_center_node)


func _new_layer_selected(layer):
	var type_str = layer.RenderType.keys()[layer.render_type]
	type_str = type_str.substr(0, 1).to_upper() + type_str.substr(1).to_lower()
	var ui_path = "res://UI/Layers/LayerManagement/%sLayerManagement.tscn" % type_str
	
	if current_layer_management_ui != null and is_instance_valid(current_layer_management_ui):
		current_layer_management_ui.queue_free()
	
	var file2check = File.new()
	if file2check.file_exists(ui_path):
		current_layer_management_ui = load(ui_path).instance()
		current_layer_management_ui.init(pc_player, layer, pos_manager)
		add_child(current_layer_management_ui)
