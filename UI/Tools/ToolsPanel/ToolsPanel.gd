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

# FIXME: None of these are found, can they be removed?
onready var tools_bar = get_node("HBoxContainer/PanelContainer/ScrollContainer/ToolsBar")
onready var panel = get_node("HBoxContainer/PanelContainer")
onready var window = get_node("HBoxContainer")


# Giving a configuration warning if a wrong item has been attached
const _required_button = preload("res://UI/Tools/ToolsButton.gd")

var arrow_toggle: bool = false


func _ready():
	apply_tool_settings(GameModeLoader.get_startup_mode())


# If the current game mode is changed, the new mode will be applied according to 
# the game-mode-settings.json-file.
func apply_tool_settings(mode: int):
	var tools: Array = GameModeLoader.get_all_tools_for_mode(mode)
	
	#for child in tools_bar.get_children():
	#	if not tools.has(child.name):
	#		child.set_disabled(true)
