extends HBoxContainer
class_name DrawLayerMenuItem

@export var layer_id: int
var swatch_element: TextureRect
var label_element: Label

var layer_name: String :
	set(n):
		layer_name = n
		if label_element:
			label_element.text = n


func _init(init_layer_name: String):
	layer_name = init_layer_name

func _ready() -> void:
	var drop_button = TableButton.new()
	drop_button.name = "DropLayerButton"
	drop_button.icon = preload("res://Resources/Icons/LabTable/circle_cross.svg")
	add_child(drop_button)
	swatch_element = TextureRect.new()
	swatch_element.custom_minimum_size = Vector2(128,128)
	swatch_element.texture = preload("res://Resources/Icons/LabTable/drawing_swatch.svg")
	add_child(swatch_element)
	label_element = Label.new()
	label_element.text = layer_name
	add_child(label_element)
	var select_button = TableButton.new()
	select_button.icon = preload("res://Resources/Icons/LabTable/buttons/next.svg")
	select_button.pressed.connect(func (): get_parent().open_dropdown(layer_id))
	add_child(select_button)
	
func register_drop_action(callable):
	$DropLayerButton.pressed.connect(func (): callable.call(layer_id))

func get_swatch_position():
	var screen_pos = swatch_element.get_screen_position() - \
		Vector2(DisplayServer.window_get_position(get_viewport().get_window().get_window_id())) \
		+ swatch_element.size / 2
	var screen_size = DisplayServer.window_get_size(get_viewport().get_window().get_window_id())
	screen_pos /= Vector2(screen_size)
	logger.info("screen " + str(screen_pos))

	return [screen_pos.x, screen_pos.y]
