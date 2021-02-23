extends Control

var scenarios: Array = []

onready var area_list = get_node("PanelContainer/HBoxContainer/VBoxContainer/AreaList")
onready var gamemode_list = get_node("PanelContainer/HBoxContainer/VBoxContainer/GameModeList")
onready var start_button = get_node("PanelContainer/HBoxContainer/VBoxContainer/Button")

func _ready():
	start_button.connect("pressed", self, "start_game")
	
	# FIXME: This will be rebuilt using the new geopackage approach
	#scenarios = Session.get_scenarios()
	#build_area_list()
	#build_gamemode_list()


# Fill the Godot UI Item List with the scenarios
func build_area_list():
	area_list.clear()
	
	var id = 0
	if scenarios:  # check for null
		for scenario in scenarios:
			area_list.add_item(scenario.name)
			area_list.set_item_metadata(id, scenario)  # Save the scenario ID in the metadata
			id += 1
	else:
		logger.error("Couldn't get scenarios!'", "StartMenuUI")
	
	# Select the first item by default
	# FIXME: Index out of bounds (size is 0)
	area_list.select(0)


func build_gamemode_list():
	gamemode_list.clear()
	
	var id = 0
	for mode in GameModeLoader.get_modes():
		gamemode_list.add_item(mode["name"])
		gamemode_list.set_item_metadata(id, mode["scene"])
		
		id += 1
	
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
	
	get_tree().change_scene(gamemode_list.get_item_metadata(selected_gamemode))
	
	GlobalSignal.emit_signal("game_started")
