extends Control

var scenarios: Dictionary = {}

onready var area_list = get_node("PanelContainer/HBoxContainer/VBoxContainer/AreaList")
onready var gamemode_list = get_node("PanelContainer/HBoxContainer/VBoxContainer/GameModeList")
onready var start_button = get_node("PanelContainer/HBoxContainer/VBoxContainer/Button")

func _ready():
	start_button.connect("pressed", self, "start_game")
	
	scenarios = Session.get_scenarios()
	build_area_list()
	build_gamemode_list()


# Fill the Godot UI Item List with the scenarios
func build_area_list():
	area_list.clear()
	
	var id = 0
	if scenarios:  # check for null
		for i in scenarios:
			area_list.add_item(scenarios[i].name)
			area_list.set_item_metadata(id, i)  # Save the scenario ID in the metadata
			id += 1
	else:
		logger.error("Couldn't get scenarios!'")
	
	# Select the first item by default
	area_list.select(0)


func build_gamemode_list():
	gamemode_list.clear()
	
	gamemode_list.add_item("Test")
	
	# Select the first item by default
	gamemode_list.select(0)


# Called when an item is clicked on
func start_game():
	# Validity checks
	if not area_list.is_anything_selected():
		return
	
	if not gamemode_list.is_anything_selected():
		return
	
	var selected_area = area_list.get_selected_items()[0]
	var selected_gamemode = gamemode_list.get_selected_items()[0]
	
	Session.set_start_offset_for_scenario(area_list.get_item_metadata(selected_area))
	get_tree().change_scene("res://GameModes/RetourWorkshop/RetourWorkshopMode.tscn")
