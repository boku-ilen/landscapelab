extends MenuButtonExtended


@export var world_ui: Control

@export var viewport: Viewport

@export var docks: Array[Control]
@export var dock_names: Array[String]


@onready var fullscreen_item = MenuItem.new(
	"Fullscreen", world_ui.on_fullscreen)
@onready var render_main_item = MenuItem.new(
	"Render Main Viewport", toggle_viewport_rendering, true, true)
@onready var docks_menu = Menu.new(
	false, "Show docks", [])
@onready var view_menu = Menu.new(
	true, "ViewMenu", [fullscreen_item, render_main_item, docks_menu])


func _ready():
	super._ready()
	var i = 0
	var test = docks_menu.popup
	for dock in docks:
		docks_menu.popup.add_check_item(dock_names[i], i)
		docks_menu.popup.set_item_checked(i, true)
		docks_menu.popup.set_item_metadata(i, func(): 
			docks[i].set_visible(not docks[i].visible)
			docks_menu.popup.set_item_checked(i, docks[i].visible))
		i += 1


func toggle_viewport_rendering():
	var idx = view_menu.menu_items.find(render_main_item)
	var active = not view_menu.popup.is_item_checked(idx)
	view_menu.popup.set_item_checked(idx, active)
	var update_mode = SubViewport.UPDATE_DISABLED if not active else SubViewport.UPDATE_ALWAYS
	viewport.render_target_update_mode = update_mode
