extends Node


@export var layer_ui_path: NodePath
@export var pos_manager_path: NodePath

@onready var layer_ui = get_node(layer_ui_path)

var current_layer_management_ui
var pc_player: AbstractPlayer
var pos_manager: PositionManager


func _ready():
	pos_manager = get_node(pos_manager_path)
	pos_manager.connect("new_center_node",Callable(self,"_on_new_center_node"))


func _on_new_center_node(new_center_node):
	pc_player = new_center_node
	
	if current_layer_management_ui:
		current_layer_management_ui.set_player(new_center_node)
