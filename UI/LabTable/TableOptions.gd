extends MenuButton


@export var player_node: Node3D
const SCENE = preload("res://UI/LabTable/LabTable.tscn")

enum TableOptions {
	OPEN,
	SET_FULLSCREEN
}


func _ready():
	var labtable_scene = SCENE.instantiate()
	labtable_scene.get_node("LabTable").debug_mode = false
	labtable_scene.get_node("LabTable").player_node = player_node
	
	var table_options = get_popup()
	
	# Add options and store callback functions in metadata to call when 
	# the option is pressed
	table_options.add_item("Open", TableOptions.OPEN)
	table_options.set_item_metadata(TableOptions.OPEN, func():
		table_options.set_item_disabled(TableOptions.OPEN, true)
		get_tree().get_root().add_child(labtable_scene)
		table_options.set_item_disabled(TableOptions.SET_FULLSCREEN, false))
	
	table_options.add_item("Set Fullscreen", TableOptions.SET_FULLSCREEN)
	table_options.set_item_disabled(TableOptions.SET_FULLSCREEN, true)
	table_options.set_item_as_checkable(TableOptions.SET_FULLSCREEN, true)
	table_options.set_item_checked(TableOptions.SET_FULLSCREEN, false)
	table_options.set_item_metadata(TableOptions.SET_FULLSCREEN, func():
		if labtable_scene.mode == Window.MODE_FULLSCREEN:
			labtable_scene.mode = Window.MODE_WINDOWED
			table_options.set_item_checked(TableOptions.SET_FULLSCREEN, false)
		else:
			labtable_scene.mode = Window.MODE_FULLSCREEN
			table_options.set_item_checked(TableOptions.SET_FULLSCREEN, true))
	
	# Connect item pressed with callback
	table_options.index_pressed.connect(
		func(idx): table_options.get_item_metadata(idx).call())
