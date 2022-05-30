extends VBoxContainer

# FIXME: To be removed or updated with GameSystem


onready var panel = get_node("PanelContainer")
onready var dropdown = get_node("Control")

onready var panel_pos_x = panel.rect_position.x
var panel_start_pos: Vector2
var _panel_unfolded: bool = false

# A dictionary of the instance paths of all available values mapped to their name
# only the values for the current mode will be loaded
var values: Dictionary


func _ready():
	dropdown.connect("item_selected", self, "_on_value_changed")
	
	#apply_value_settings(GameModeLoader.get_startup_mode())
	# Load the default selected (index 0) energy-ui
	#_on_value_changed(0)



# If the current game mode is changed, the new mode will be applied according to 
# the game-mode-settings.json-file.
func apply_value_settings(mode: int):
	pass
#	values = GameModeLoader.get_all_values_for_mode(mode)
#
#	# Fill in each label of the values
#	for value in values:
#		dropdown.add_item(value)


func _on_value_changed(id: int):
	# Clear any other ui currently loaded
	for child in panel.get_children():
		child.queue_free()
	
	# Load the data from the values-settings.json
	var path_to_scene = values[dropdown.get_item_text(id)]
	var value_ui = load(path_to_scene)
	panel.add_child(value_ui.instance())
	
	# As the size of the panel-size changes with another value-ui we have to 
	# adjust the panel so it is not fully shown and can be unfolded via buttonclick
	panel_start_pos = Vector2(panel_pos_x, panel.rect_size.y - 30)
	if !_panel_unfolded:
		panel.set_position(panel_start_pos)
