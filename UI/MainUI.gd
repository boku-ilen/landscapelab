extends Control

#
# In the current state, this node is the root node of the LL.
#

var docks = []
signal ui_loaded

# Often used nodes that can be injected to the UIDocks if required
export(NodePath) var pc_player_path
export(NodePath) var pos_manager_path


func _ready():
	docks.append($MarginContainer/Split/Left/Left/Top)
	docks.append($MarginContainer/Split/Left/Left/Bot)
	docks.append($MarginContainer/Split/Left/Right/Top)
	docks.append($MarginContainer/Split/Left/Right/Bot)
	docks.append($MarginContainer/Split/Right/Mid/VBoxContainer)
	docks.append($MarginContainer/Split/Right/Right/Left/Top)
	docks.append($MarginContainer/Split/Right/Right/Left/Bot)
	docks.append($MarginContainer/Split/Right/Right/Right/Top)
	docks.append($MarginContainer/Split/Right/Right/Right/Bot)
	
	_inject()
	emit_signal("ui_loaded")


func _process(delta):
	var engine_pos = get_node(pc_player_path).transform.origin
	var geo_pos = engine_pos + Vector3(get_node(pos_manager_path).x, 0, get_node(pos_manager_path).z)
	var formatted = "Engine-Position: x=%.2f, y=%.2f, z=%.2f\n\nGeo-Position: x=%.2f, y=%.2f, z=%.2f"
	formatted = formatted % [engine_pos.x, engine_pos.y, engine_pos.z, geo_pos.x, geo_pos.y, geo_pos.z]
	
	$MarginContainer/Split/Right/Mid/HBoxContainer/Position.text = formatted


func _inject():
	for dock in docks:
		for child in dock.get_children():
			if "pc_player" in child:
				child.pc_player = get_node(pc_player_path)
			if "pos_manager" in child:
				child.pos_manager = get_node(pos_manager_path)
			if child.has_method("_on_ui_loaded"):
				connect("ui_loaded", child, "_on_ui_loaded")


