extends HBoxContainer

#
# This script handles the UI-Element of the points of interest.
#

# All the ui elements for the PoI UI functionality
@onready var parent_button = get_parent()
@onready var input_field = get_node("VBoxContainer/TextEdit")
@onready var save_button = get_node("VBoxContainer/Save")
@onready var item_list = get_node("VBoxContainer/ItemList")
@onready var add_button = get_node("VBoxContainer/HBoxContainer/Add")
@onready var delete_button = get_node("VBoxContainer/HBoxContainer/Delete")

var pos_manager: PositionManager
var pc_player: AbstractPlayer
var current_poi_layer: LayerComposition
var last_teleport_name: String

signal teleported(poi_name: String)


func _ready():
	$VBoxContainer/TeleportToButton.connect("pressed",Callable(self,"_teleport_current_values"))
	$VBoxContainer/OptionButton.connect("item_selected",Callable(self,"_change_selected_layer"))
	$VBoxContainer/ItemList.connect("item_selected",Callable(self,"_on_feature_select"))
	add_button.connect("pressed",Callable(self,"_on_add_pressed"))
	save_button.connect("pressed",Callable(self,"_on_save_pressed"))
	delete_button.connect("pressed",Callable(self,"_on_delete_pressed"))
	
	var object_layers = Layers.get_layers_with_render_info(LayerComposition.ObjectRenderInfo)
	
	for layer in object_layers:
		_add_object_layer(layer)
	
	Layers.new_layer_composition.connect(_add_object_layer)
	Layers.removed_rendered_layer_composition.connect(_remove_object_layer_composition)


func _teleport_current_values():
	teleport_to_coordinates(Vector3(
		$VBoxContainer/HBoxContainer2/X.value, 
		$VBoxContainer/HBoxContainer2/Y.value, 
		$VBoxContainer/HBoxContainer2/Z.value), 
		true)


# Teleports to engine- or geo-coordinates (of the current projection)
func teleport_to_coordinates(xyz: Vector3, geo_coords=true):
	if geo_coords:
		xyz = pos_manager.to_engine_coordinates(xyz)
	if pc_player:
		print(xyz)
		pc_player.teleport(xyz)
	else:
		# FIXME: what if center node is not a player?
		pass


func _add_object_layer(layerc: LayerComposition):
	if layerc.render_info is LayerComposition.ObjectRenderInfo:
		$VBoxContainer/OptionButton.add_item(layerc.name)


func _remove_object_layer_composition(lcname: String, render_info):
	if render_info is LayerComposition.ObjectRenderInfo:
		# Items in option buttons are so weird... Every fifth entry is the 
		# name of another item
		var index = $VBoxContainer/OptionButton.items.find(lcname) / 5
		$VBoxContainer/OptionButton.remove_item(index)


func _change_selected_layer(id: int):
	var layer_name = $VBoxContainer/OptionButton.get_item_text(id)
	current_poi_layer = Layers.layer_compositions[layer_name]
	_load_features_into_list()


func _load_features_into_list():
	$VBoxContainer/ItemList.clear()
	
	var features = current_poi_layer.render_info.geo_feature_layer.get_all_features()
	
	for feature in features:
		var new_id = $VBoxContainer/ItemList.get_item_count()
		var pos = feature.get_vector3()
		pos.z = -pos.z # Adapt to engine -z forward
		
		var item_name = str(pos)
		var name_attribute = current_poi_layer.ui_info.name_attribute
		name_attribute = name_attribute if name_attribute != null else "name"
		if feature.get_attribute(name_attribute) != "" and feature.get_attribute(name_attribute) != null:
			item_name = feature.get_attribute(name_attribute)
		
		var height = 0
		if feature.get_attribute("hoehe") != null and feature.get_attribute("hoehe") != "":
			height = float(feature.get_attribute("hoehe"))
		
		var metadata = {"pos": pos, "feature": feature, "height": height}
		$VBoxContainer/ItemList.add_item(item_name)
		$VBoxContainer/ItemList.set_item_metadata(new_id, metadata)


func _on_feature_select(item_id):
	var global_pos = $VBoxContainer/ItemList.get_item_metadata(item_id)["pos"]
	global_pos.y = $VBoxContainer/ItemList.get_item_metadata(item_id)["height"]
	teleport_to_coordinates(global_pos, true)
	release_focus()
	
	last_teleport_name = $VBoxContainer/ItemList.get_item_text(item_id)
	teleported.emit(last_teleport_name)


func _on_add_pressed():
	input_field.visible = true
	save_button.visible = true


func _on_save_pressed():
	var new_feature = current_poi_layer.create_feature()
	
	var global_center = pos_manager.get_center()
	new_feature.set_offset_vector3(pc_player.position, 
			global_center[0], 0, global_center[1])
	
	# FIXME: this is a limitation as of now as set_attribute only works
	# FIXME: checked an existing table row. This needs to be created first
	var key = current_poi_layer.ui_info.name_attribute
	key = key if key != null else "name"
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
