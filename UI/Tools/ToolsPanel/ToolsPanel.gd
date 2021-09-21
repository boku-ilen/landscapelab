extends BoxContainer

#
# This node handels all the logic of the ToolsPanel. 
# In order to have a new tool, add a toolsbutton and instance the corresponding
# UI. A configuration warning will be given if a wrong button is attached.
#
# The panel has a default position mostly out of the ui. 
# Once hovered the buttons are visible.
# On toggle it will unfold and show additional information to the buttons.
#


# Giving a configuration warning if a wrong item has been attached
const _required_button = preload("res://UI/Tools/ToolsButton.gd")

var arrow_toggle: bool = false
var pc_player: AbstractPlayer
var pos_manager


func _ready():
	pass
	# FIXME: Not working because of the rebuild - adapt the GameModeLoader!
	#apply_tool_settings(GameModeLoader.get_startup_mode())


func _on_ui_loaded():
	_inject()


func _inject():
	for child in $ScrollContainer/ToolsBar.get_children():
		if "pc_player" in child:
			child.pc_player = pc_player
		if "pos_manager" in child:
			child.pos_manager = pos_manager
		
		for subchild in child.get_children():
			if subchild.get_child_count() > 1:
				# .get_child(1) is needed because the ToolsButton places everything
				# under a new root node, and the window dialogue has a default child
				# which is get_child(0)
				if "pc_player" in subchild.get_child(1):
					subchild.get_child(1).pc_player = pc_player
				if "pos_manager" in subchild.get_child(1):
					subchild.get_child(1).pos_manager = pos_manager


# If the current game mode is changed, the new mode will be applied according to 
# the game-mode-settings.json-file.
func apply_tool_settings(mode: int):
	var tools: Array = GameModeLoader.get_all_tools_for_mode(mode)
	
	#for child in tools_bar.get_children():
	#	if not tools.has(child.name):
	#		child.set_disabled(true)
