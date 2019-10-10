extends Control


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
	
	var name = input_field.text
	PlayerInfo.get_true_player_position()
	
	# TODO: Request on server for adding current position to PoIs


func _on_Delete_pressed():
	# select mode is set to single, so only one item can be selected
	var current_item = item_list.get_selected_items()
	
	# TODO: Request for deleting a PoI by giving the name to the server
