@tool
extends TextureButton

@export var more_info_nodes: Array[Control]


func _ready() -> void:
	for node in more_info_nodes:
		node.visible = button_pressed


func _toggled(toggled_on: bool) -> void:
	for node in more_info_nodes:
		node.visible = toggled_on
