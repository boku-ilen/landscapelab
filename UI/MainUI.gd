extends Control

#
# In the current state, this node is the root node of the LL.
#

var docks = []
signal ui_loaded

# Often used nodes that can be injected to the UIDocks if required
export(NodePath) var pc_player_path


func _ready():
	docks.append($MarginContainer/Split/Left/Left/Top)
	docks.append($MarginContainer/Split/Left/Left/Bot)
	docks.append($MarginContainer/Split/Left/Right/Top)
	docks.append($MarginContainer/Split/Left/Right/Bot)
	docks.append($MarginContainer/Split/Right/Right/Left/Top)
	docks.append($MarginContainer/Split/Right/Right/Left/Bot)
	docks.append($MarginContainer/Split/Right/Right/Right/Top)
	docks.append($MarginContainer/Split/Right/Right/Right/Bot)
	
	_inject()
	emit_signal("ui_loaded")


func _inject():
	for dock in docks:
		for child in dock.get_children():
			if "pc_player" in child:
				child.pc_player = get_node(pc_player_path)
			if child.has_method("_on_ui_loaded"):
				connect("ui_loaded", child, "_on_ui_loaded")


