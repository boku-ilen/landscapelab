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
var pc_player: AbstractPlayer
var current_poi_layer: Layer

const LOG_MODULE := "UI"


func _ready():
	$VBoxContainer/TeleportToButton.connect("pressed", self, "_teleport_current_values")
	$VBoxContainer/OptionButton.connect("item_selected", self, "_change_selected_layer")
	$VBoxContainer/ItemList.connect("item_selected", self, "_on_feature_select")
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


func _add_object_layer(layer: Layer):
	if layer.render_type == Layer.RenderType.OBJECT:
		$VBoxContainer/OptionButton.add_item(layer.name)


func _remove_object_layer(lname: String, render_type):
	if render_type == Layer.RenderType.OBJECT:
		# Items in option buttons are so weird... Every fifth entry is the 
		# name of another item
		var index = $VBoxContainer/OptionButton.items.find(lname) / 5
		$VBoxContainer/OptionButton.remove_item(index)


func _change_selected_layer(id: int):
	var layer_name = $VBoxContainer/OptionButton.get_item_text(id)
	current_poi_layer = Layers.layers[layer_name]
	_load_features_into_list()


func _load_features_into_list():
	$VBoxContainer/ItemList.clear()
	
	var features = current_poi_layer.get_features_near_position(0, 0, 1000000000, 100)
	
	for feature in features:
		var new_id = $VBoxContainer/ItemList.get_item_count()
		var position = feature.get_vector3()
		# TODO: Why do we need to reverse the z coordinate? seems like an inconsistency in coordinate handling
		position.z = -position.z
		
		var item_name = feature.get_attribute(current_poi_layer.ui_info.name_attribute) \
				if feature.get_attribute(current_poi_layer.ui_info.name_attribute) != "" \
				else str(position)
		
		var metadata = {"pos": position, "feature": feature}
		$VBoxContainer/ItemList.add_item(item_name)
		$VBoxContainer/ItemList.set_item_metadata(new_id, metadata)


func _on_feature_select(item_id):
	var global_pos = $VBoxContainer/ItemList.get_item_metadata(item_id)["pos"]
	teleport_to_coordinates(global_pos, true)


func _on_add_pressed():
	input_field.visible = true
	save_button.visible = true


func _on_save_pressed():
	var new_feature = current_poi_layer.create_feature()
	
	var global_center = pos_manager.get_center()
	new_feature.set_offset_vector3(pc_player.translation, 
			global_center[0], 0, global_center[1])
	
	# FIXME: this is a limitation as of now as set_attribute only works
	# FIXME: on an existing table row. This needs to be created first
	var key = current_poi_layer.ui_info.name_attribute
	var val = input_field.text 
	new_feature.set_attribute(key, val)
	var test = new_feature.get_attribute(key)
	
	_load_features_into_list()
	
	input_field.set_text("")
	input_field.visible = false
	save_button.visible = false


func _on_delete_pressed():
	# select mode is set to single, so only one item can be selected
	var current_item = item_list.get_selected_items()[0]
	var feature = item_list.get_item_metadata(current_item)["feature"]
	current_poi_layer.remove_feature(feature)


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
