extends HBoxContainer
class_name DrawLayerMenuItem

@export var layer_id: int
var swatch_element: TextureRect

func _ready() -> void:
	var drop_button = TableButton.new()
	drop_button.name = "DropLayerButton"
	drop_button.icon = preload("res://Resources/Icons/LabTable/circle_cross.svg")
	add_child(drop_button)
	swatch_element = TextureRect.new()
	swatch_element.custom_minimum_size = Vector2(128,128)
	swatch_element.texture = preload("res://Resources/Icons/LabTable/drawing_swatch.svg")
	add_child(swatch_element)
	
func register_drop_action(callable):
	$DropLayerButton.pressed.connect(func (): callable.call(layer_id))

func get_swatch_position():
	var screen_pos = swatch_element.get_screen_position() - \
		Vector2(DisplayServer.window_get_position(get_viewport().get_window().get_window_id())) \
		+ swatch_element.size / 2
	var screen_size = DisplayServer.screen_get_size(get_viewport().get_window().get_window_id())
	screen_pos /= Vector2(screen_size)
	logger.info("screen " + str(screen_pos))

	return [screen_pos.x, screen_pos.y]
