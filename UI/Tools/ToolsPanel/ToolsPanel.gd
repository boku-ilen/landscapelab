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
var pos_manager: PositionManager
var time_manager: TimeManager
var weather_manager: WeatherManager


func _ready():
	pass
	# FIXME: Not working because of the rebuild - adapt the GameModeLoader!
	#apply_tool_settings(GameModeLoader.get_startup_mode())


func _on_ui_loaded():
	_search_injections()


func _search_injections():
	for child in $ScrollContainer/ToolsBar.get_children():
		_inject(child)
		
		for subchild in child.get_children():
			if subchild.get_child_count() > 1:
				# .get_child(1) is needed because the ToolsButton places everything
				# under a new root node, and the window dialogue has a default child
				# which is get_child(0)
				_inject(subchild.get_child(1))


func _inject(node: Node):
	if "pc_player" in node:
		node.pc_player = pc_player
	if "pos_manager" in node:
		node.pos_manager = pos_manager
	if "time_manager" in node:
		node.time_manager = time_manager
	if "weather_manager" in node:
		node.weather_manager = weather_manager


# If the current game mode is changed, the new mode will be applied according to 
# the game-mode-settings.json-file.
func apply_tool_settings(mode: int):
	pass
#	var tools: Array = GameModeLoader.get_all_tools_for_mode(mode)
	
	#for child in tools_bar.get_children():
	#	if not tools.has(child.name):
	#		child.set_disabled(true)
