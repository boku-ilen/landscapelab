extends HBoxContainer

#
# This script handles the UI-Element of the points of interest.
#

# All the ui elements for the PoI UI functionality
onready var parent_button = get_parent()
onready var input_field = get_node("VBoxContainer/TextEdit")
onready var save_button = get_node("VBoxContainer/Save")
onready var item_list = get_node("VBoxContainer/ItemList")
onready var add_button = get_node("VBoxContainer/HBoxContainer/Add")
onready var delete_button = get_node("VBoxContainer/HBoxContainer/Delete")
onready var arrow_up = get_node("Arrows/ArrowUp")
onready var arrow_down = get_node("Arrows/ArrowDown")

var pos_manager: PositionManager
var pc_player
var current_poi_layer: Layer

const LOG_MODULE := "UI"


func _ready():
	$VBoxContainer/TeleportToButton.connect("pressed", self, "_teleport_current_values")
	$VBoxContainer/OptionButton.connect("item_selected", self, "_change_selected_layer")
	add_button.connect("pressed", self, "_on_add_pressed")
	save_button.connect("pressed", self, "_on_save_pressed")
	delete_button.connect("pressed", self, "_on_delete_pressed")
	arrow_up.connect("pressed", self, "_on_arrow_up")
	arrow_down.connect("pressed", self, "_on_arrow_down")
	
	var object_layers = Layers.get_layers_of_type(Layer.RenderType.OBJECT)
	for layer in object_layers:
		_add_object_layer(layer)
	
	Layers.connect("new_layer", self, "_add_object_layer")
	Layers.connect("removed_rendered_layer", self, "_remove_object_layer")


func _teleport_current_values():
	teleport_to_coordinates(Vector3($VBoxContainer/HBoxContainer2/X.value, 
		$VBoxContainer/HBoxContainer2/Y.value, $VBoxContainer/HBoxContainer2/Z.value), true)


# Teleports to engine- or geo-coordinates (of the current projection)
func teleport_to_coordinates(xyz: Vector3, geo_coords=true):
	if geo_coords:
		xyz = pos_manager.to_engine_coordinates(xyz)
	if pc_player:
		pc_player.translation = xyz
	else:
		# FIXME: what if center node is not a player?
		pass


func _remove_object_layer(lname: String, render_type):
	if render_type == Layer.RenderType.OBJECT:
		# Items in option buttons are so weird... Every fifth entry is the 
		# name of another item
		var index = $VBoxContainer/OptionButton.items.find(lname) / 5
		$VBoxContainer/OptionButton.remove_item(index)


func _add_object_layer(layer: Layer):
	if layer.render_type == Layer.RenderType.OBJECT:
		$VBoxContainer/OptionButton.add_item(layer.name)


func _change_selected_layer(id: int):
	var layer_name = $VBoxContainer/OptionButton.get_item_text(id)
	current_poi_layer = Layers.layers[layer_name]
	

# Points of interest UI functionality
func _on_add_pressed():
	input_field.visible = true
	save_button.visible = true


func _on_save_pressed():
	# Create an array for the locations data (only contains "x" and "z"-axis)
	# FIXME: Get the player position here
	var fixed_pos = [0, 0]
	
	# Search for bad url characters
	var regex = RegEx.new()
	regex.compile(".*[!@#$%^&*(),.?\"\/\\\\:{}|<>].*")
	var has_bad_chars = regex.search(input_field.text)
	
	if has_bad_chars:
		logger.warning("New PoI name must not contain special characters", LOG_MODULE)
		input_field.set_text("No special characters!")
		return
	
	# To escape whitespaces use ``.percent_encode()``
	var url_escaped_input = input_field.text.percent_encode()
	
	# As the coordinates on the server are responded in a different type,
	# we have to use a "-" on the x-axis to properly save it
	#FIXME: we have to decide how we want to provide this functionallity after
	#FIXME: the locations come from a (should be readonly) geopackage
	var result = "" # ServerConnection.get_json("/location/create/%s/%d.0/%d.0/%d" % [url_escaped_input, -fixed_pos[0], fixed_pos[1], Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.creation_success:
		item_list.add_item(input_field.text)
		# The item will be added as the last element in the list
		item_list.set_item_metadata(item_list.get_item_count() - 1, fixed_pos)
	
	input_field.set_text("")
	input_field.visible = false
	save_button.visible = false


func _on_delete_pressed():
	# select mode is set to single, so only one item can be selected
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)

	#FIXME: we have to decide how we want to provide this functionallity after
	#FIXME: the locations come from a (should be readonly) geopackage
	var result = "" # ServerConnection.get_json("/location/remove/%s/%d" % [item_text, Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.removal_success:
		item_list.remove_item(current_item)


func _on_arrow_up():
	# FIXME: this crashes the landscapelab if the POI list is empty
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)
	
	#var result = ServerConnection.get_json("/location/increase_order/%s/%d" % [item_text, Session.scenario_id], false)
	
	item_list.move_item(current_item, current_item - 1)


func _on_arrow_down():
	# FIXME: this crashes the landscapelab if the POI list is empty
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)
	
	#var result = ServerConnection.get_json("/location/increase_order/%s/%d" % [item_text, Session.scenario_id], false)
	
	item_list.move_item(current_item, current_item + 1)
