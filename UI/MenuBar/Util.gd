extends MenuButtonExtended


@export var action_handler_3d_path: Node
@export var position_manager: PositionManager
@export var player_node: Node3D
@export var weather_manager: WeatherManager
@export var time_manager: TimeManager

const TABLESCENE = preload("res://UI/LabTable/LabTable.tscn")
const DOLLYSCENE = preload("res://UI/DollyCamera/DollyWindow.tscn")


var open_dolly_item = MenuItem.new(
	"Open Dolly", _begin_dolly)
var open_table_item = MenuItem.new(
	"Open LabTable", _open_labtable)
var open_weather_ui_item = MenuItem.new(
	"Open Weather Menu", func():
		var weather_menu = preload("res://UI/Weather/WeatherUIWindow.tscn").instantiate()
		get_tree().get_root().add_child(weather_menu)
		weather_menu.popup_centered()
		weather_menu.weather_manager = weather_manager
)
var open_datetime_ui_item = MenuItem.new(
	"Open DateTime Menu", func():
		var datetime_menu = preload("res://UI/Datetime/DatetimeWindow.tscn").instantiate()
		get_tree().get_root().add_child(datetime_menu)
		datetime_menu.popup_centered()
		datetime_menu.time_manager = time_manager
)
var open_layer_ui_item = MenuItem.new(
	"Open Layer Menu", func():
		var menu = preload("res://UI/Layers/LayerConfiguration/LayerCompositionUIWindow.tscn").instantiate()
		menu.position_manager = position_manager
		get_tree().get_root().add_child(menu)
		menu.popup_centered()
)

var window_menu = Menu.new(
	true, "WindowMenu", [open_dolly_item, open_table_item, open_weather_ui_item, open_datetime_ui_item, open_layer_ui_item])

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


func _begin_dolly():
	if not dolly_window.is_inside_tree():
		get_tree().get_root().add_child(dolly_window)
	
	dolly_window.popup()
	dolly_window.position_manager = position_manager


func _cleanup_dolly():
	dolly_window.hide()
