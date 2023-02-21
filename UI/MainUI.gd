extends Control

#
# In the current state, this node is the root node of the LL.
#

var docks = []
signal ui_loaded

# Often used nodes that can be injected to the UIDocks if required
@export var pc_player_path: NodePath
@export var pos_manager_path: NodePath
@export var time_manager_path: NodePath
@export var weather_manager_path: NodePath

var pos_manager: PositionManager

func _ready():
	docks.append($MarginContainer/VBoxContainer/Left/Tabs/Top)
	docks.append($MarginContainer/VBoxContainer/Left/Tabs/Bot)
	docks.append($MarginContainer/VBoxContainer/Left/Mid/Right/Tabs/Top)
	docks.append($MarginContainer/VBoxContainer/Left/Mid/Right/Tabs/Bot)
	docks.append($MarginContainer/VBoxContainer/Left/Mid/MidVertical/VBoxContainer)
	
	
	pos_manager = get_node(pos_manager_path)
	
	_inject()
	emit_signal("ui_loaded")


func _process(delta):
	var engine_pos = pos_manager.center_node.position
	var geo_pos = pos_manager.to_world_coordinates(engine_pos)
	var formatted = "x=%.2f, y=%.2f, z=%.2f\nx=%.0f, y=%.0f, z=%.0f"
	formatted = formatted % [engine_pos.x, engine_pos.y, engine_pos.z, geo_pos[0], geo_pos[1], geo_pos[2]]
	
	$MarginContainer/VBoxContainer/Left/Mid/MidVertical/HBoxContainer/DebugInfo/ScrollContainer/Settings/VBoxContainer/Info/PositionDisplay/Data.text = formatted


func _inject():
	for dock in docks:
		for child in dock.get_children():
			if "pc_player" in child:
				child.pc_player = get_node(pc_player_path)
			if "pos_manager" in child:
				child.pos_manager = get_node(pos_manager_path)
			if "time_manager" in child:
				child.time_manager = get_node(time_manager_path)
			if "weather_manager" in child:
				child.weather_manager = get_node(weather_manager_path)
			if child.has_method("_on_ui_loaded"):
				connect("ui_loaded",Callable(child,"_on_ui_loaded"))


