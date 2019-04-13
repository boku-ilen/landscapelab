extends Control

var scenarios = []

onready var item_list = get_node("MarginContainer/HBoxContainer/VBoxContainer/ItemList")

func _ready():
	item_list.connect("item_activated", self, "_on_item_activated")
	
	scenarios = Session.get_scenarios()
	build_item_list()


# Fill the Godot UI Item List with the scenarios
func build_item_list():
	item_list.clear()
	
	var id = 0
	for i in scenarios:
		item_list.add_item(scenarios[i].name)
		item_list.set_item_metadata(id, i)  # Save the scenario ID in the metadata
		id += 1


# Called when an item is clicked on
func _on_item_activated(index):
	Session.load_scenario(item_list.get_item_metadata(index))
	get_tree().change_scene("res://World/MainScene/MainScene.tscn")