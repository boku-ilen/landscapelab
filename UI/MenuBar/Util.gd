extends MenuButtonExtended


@export var action_handler_3d_path: Node
@export var position_manager: PositionManager
@export var player_node: Node3D
@export var weather_manager: WeatherManager
@export var time_manager: TimeManager

const TABLESCENE = preload("res://UI/LabTable/LabTable.tscn")
const DOLLYSCENE = preload("res://UI/DollyCamera/DollyWindow.tscn")


var open_dolly_item = MenuItem.new(
	"Open...", _begin_dolly)
var open_table_item = MenuItem.new(
	"Open...", _open_labtable)
var table_fullscreen_item = MenuItem.new(
	"Set Fullscreen", _set_labtable_fullscreen, true, false)

var imaging_menu = Menu.new(
	false, "ImagingMenu", [open_dolly_item])
var labtable_menu = Menu.new(
	false, "LabTableMenu", [open_table_item, table_fullscreen_item])
var util_menu = Menu.new(
	true, "UtilMenu", [imaging_menu, labtable_menu])

var dolly_window: Window
var labtable_window: Window


func _ready():
	super._ready()
	dolly_window = DOLLYSCENE.instantiate()
	dolly_window.visible = false
	
	dolly_window.action_handlers = [action_handler_3d_path]
	dolly_window.close_requested.connect(_cleanup_dolly)


func _open_labtable():
	if labtable_window == null:
		labtable_window = TABLESCENE.instantiate()
		labtable_window.get_node("LabTable").player_node = player_node
		labtable_window.get_node("LabTable").time_manager = time_manager
		labtable_window.get_node("LabTable").weather_manager = weather_manager
	if not labtable_window.is_inside_tree():
		get_tree().get_root().add_child(labtable_window)
	
	labtable_menu.popup.set_item_disabled(
		labtable_menu.menu_items.find(open_table_item), true)
	labtable_menu.popup.set_item_disabled(
		labtable_menu.menu_items.find(table_fullscreen_item), false)


func _set_labtable_fullscreen():
	if labtable_window.mode == Window.MODE_FULLSCREEN:
		labtable_window.mode = Window.MODE_WINDOWED
		labtable_menu.popup.set_item_checked(
			labtable_menu.menu_items.find(table_fullscreen_item), false)
	else:
		labtable_window.mode = Window.MODE_FULLSCREEN
		labtable_menu.popup.set_item_checked(
			labtable_menu.menu_items.find(table_fullscreen_item), true)


func _begin_dolly():
	if not dolly_window.is_inside_tree():
		get_tree().get_root().add_child(dolly_window)
	
	dolly_window.popup()
	dolly_window.position_manager = position_manager
	
	imaging_menu.popup.set_item_disabled(imaging_menu.menu_items.find(open_dolly_item), true)


func _cleanup_dolly():
	dolly_window.hide()
	imaging_menu.popup.set_item_disabled(imaging_menu.menu_items.find(open_dolly_item), false)
