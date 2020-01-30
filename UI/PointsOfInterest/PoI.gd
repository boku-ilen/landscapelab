extends HBoxContainer

#
# This script handles the UI-Element of the points of interest.
#


onready var input_field = get_node("VBoxContainer/TextEdit")
onready var save_button = get_node("VBoxContainer/Save")
onready var item_list = get_node("VBoxContainer/ItemList")


func _on_ItemList_item_activated(index):
	GlobalSignal.emit_signal("poi_clicked", index)


func _on_Add_pressed():
	input_field.visible = true
	save_button.visible = true


func _on_Save_pressed():
	input_field.visible = false
	save_button.visible = false
	
	# Create an array for the locations data (only contains "x" and "z"-axis)
	var fixed_pos = [PlayerInfo.get_true_player_position()[0], PlayerInfo.get_true_player_position()[2]]
	
	# As the coordinates on the server are responded in a different type,
	# we have to use a "-" on the x-axis to properly save it
	var result = ServerConnection.get_json("/location/create/%s/%d.0/%d.0/%d" % [input_field.text, -fixed_pos[0], fixed_pos[1], Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.creation_success:
		item_list.add_item(input_field.text)
		# The item will be added as the last element in the list
		item_list.set_item_metadata(item_list.get_item_count() - 1, fixed_pos)


func _on_Delete_pressed():
	# select mode is set to single, so only one item can be selected
	var current_item : int = item_list.get_selected_items()[0]
	var item_text : String = item_list.get_item_text(current_item)
	
	var result = ServerConnection.get_json("/location/remove/%s/%d" % [item_text, Session.scenario_id], false)
	
	# Only store on client if it was also successfully stored on server
	if result.removal_success:
		item_list.remove_item(current_item)


func _on_ArrowUp_pressed():
	var current_item : int = item_list.get_selected_items()[0]
	
	var result = ServerConnection.get_json("/location/remove/%s/%d" % [item_text, Session.scenario_id], false)
	
	item_list.move_item(current_item, current_item - 1)


func _on_ArrowDown_pressed():
	var current_item : int = item_list.get_selected_items()[0]
	
	item_list.move_item(current_item, current_item + 1)
