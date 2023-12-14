extends MenuButton


@export var world_ui: Control

@export var viewport: Viewport

@export var docks: Array[Control]
@export var dock_names: Array[String]

@onready var table_options = get_popup()

enum TableOptions {
	SET_FULLSCREEN,
	RENDER_MAIN,
	SHOW_DOCKS
}


func _ready():
	# Add options and store callback functions in metadata to call when 
	# the option is pressed
	table_options.add_item("Set Fullscreen", TableOptions.SET_FULLSCREEN)
	table_options.set_item_as_checkable(TableOptions.SET_FULLSCREEN, true)
	table_options.set_item_checked(TableOptions.SET_FULLSCREEN, false)
	table_options.set_item_metadata(TableOptions.SET_FULLSCREEN, world_ui.on_fullscreen)
	
	table_options.add_check_item("Render main Viewport", TableOptions.RENDER_MAIN)
	table_options.set_item_checked(TableOptions.RENDER_MAIN, true)
	table_options.set_item_metadata(TableOptions.RENDER_MAIN, toggle_viewport_rendering)
	
	var visible_options = PopupMenu.new()
	visible_options.name = "VisibilityPopup"
	table_options.add_child(visible_options)
	table_options.add_submenu_item("Show...", "VisibilityPopup", TableOptions.SHOW_DOCKS)
	var submenu_name = table_options.get_item_submenu(0)
	
	var i = 0
	for dock in docks:
		visible_options.add_check_item(dock_names[i], i)
		visible_options.set_item_checked(i, false)
		visible_options.set_item_metadata(i, func(): 
			docks[i].set_visible(not docks[i].visible)
			visible_options.set_item_checked(i, docks[i].visible))
		i += 1
	visible_options.index_pressed.connect(
		func(idx): visible_options.get_item_metadata(idx).call())
	
	
	# Connect item pressed with callback
	table_options.index_pressed.connect(
		func(idx): table_options.get_item_metadata(idx).call())


func toggle_viewport_rendering():
	var active = table_options.is_item_checked(TableOptions.RENDER_MAIN)
	var update_mode = SubViewport.UPDATE_DISABLED if not active else SubViewport.UPDATE_ALWAYS
	viewport.render_target_update_mode = update_mode
