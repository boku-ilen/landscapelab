extends "res://UI/LoadingIndicator.gd"


func _ready():
	pivot_offset = size / 2


func _process(delta):
	rotation += TAU * delta
