extends VBoxContainer
tool

#
# This node handels all the logic of the ToolsPanel. 
# In order to have a new tool, add a toolsbutton and instance the corresponding
# UI. A configuration warning will be given if a wrong button is attached.
#
# The panel has a default position mostly out of the ui. 
# Once hovered the buttons are visible.
# On toggle it will unfold and show additional information to the buttons.
#

onready var tools_bar = get_node("HBoxContainer/PanelContainer/ScrollContainer/ToolsBar")
onready var popups = get_node("HBoxContainer/PopupsContainer")
onready var arrow = get_node("Button")
onready var panel = get_node("HBoxContainer/PanelContainer")
onready var window = get_node("HBoxContainer")

# Define the offset of the window
export(int) var start_pos_diff
export(int) var hovered_pos_diff

# The specific positions on where the windows should be when toggled, hovered and default
onready var panel_toggled_pos = window.rect_position
onready var panel_hovered_pos = Vector2(window.rect_position.x - hovered_pos_diff, window.rect_position.y)
onready var panel_start_pos = Vector2(window.rect_position.x - start_pos_diff, window.rect_position.y)

# Giving a configuration warning if a wrong item has been attached
const _required_button = preload("res://UI/Tools/ToolsButton.gd")

var arrow_toggle: bool = false


func _ready():
	panel.connect("mouse_exited", self, "_on_mouse_exited")
	panel.connect("mouse_entered", self, "_on_mouse_entered")
	arrow.connect("toggled", self, "_on_arrow_toggle")
	UISignal.connect("ui_loaded", self, "_on_ui_loaded")
	set_position(panel_start_pos)
	
	for child in tools_bar.get_children():
		var has_required_property = true
		if not "popups_container" in child:
			has_required_property = false
				
		assert(has_required_property)
			
		child.set_popups_container(popups)
	
	apply_tool_settings(GameModeLoader.get_startup_mode())


# If the current game mode is changed, the new mode will be applied according to 
# the game-mode-settings.json-file.
func apply_tool_settings(mode: int):
	# TODO: Fix hardcoding for mode
	var tools: Array = GameModeLoader.get_all_tools_for_mode(mode)
	
	for child in tools_bar.get_children():
		if not tools.has(child.name):
			child.set_disabled(true)


func _on_mouse_entered():
	if !arrow_toggle:
		arrow.set_rotation_degrees(180)
		window.set_position(panel_hovered_pos)


func _on_mouse_exited():
	if !arrow_toggle:
		arrow.set_rotation_degrees(-90)
		window.set_position(panel_start_pos)


func _on_arrow_toggle(toggled):
	arrow_toggle = toggled
	if toggled:
		window.set_position(panel_toggled_pos)
		arrow.set_rotation_degrees(90)
	else:
		window.set_position(panel_start_pos)
		arrow.set_rotation_degrees(-90)


func _on_ui_loaded():
	window.set_position(panel_start_pos)


# Tool specific tool for showing errors in the editor
func _get_configuration_warning():
	for child in get_node("HBoxContainer/PanelContainer/ScrollContainer/ToolsBar").get_children():
		var is_required_type = child is _required_button
		
		if not is_required_type:
			return "One or more child(ren) do not extend the required ToolsButton"
	
	return ""
