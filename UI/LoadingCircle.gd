extends "res://UI/LoadingIndicator.gd"


func _ready():
	rect_pivot_offset = rect_size / 2


func _process(delta):
	rect_rotation += 2
