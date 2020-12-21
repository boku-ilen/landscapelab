extends Node
tool

export var width: float setget set_width

onready var border_node: Control = get_parent()
onready var line_up = get_node("LineUp")
onready var line_down = get_node("LineDown")
onready var line_right = get_node("LineRight")
onready var line_left = get_node("LineLeft")


func set_width(w: float):
	width = w
	get_node("LineDown").width = w
	get_node("LineUp").width = w
	get_node("LineRight").width = w
	get_node("LineLeft").width = w


func _ready():
	draw_border()


func _process(delta):
	draw_border()


func draw_border():
	if border_node is BoxContainer:
		line_up.add_point(Vector2(0, width))
		line_up.add_point(Vector2(-border_node.rect_size.x, width))
		line_down.add_point(Vector2(0, border_node.rect_size.y - width ))
		line_down.add_point(Vector2(-border_node.rect_size.x, border_node.rect_size.y - width))
