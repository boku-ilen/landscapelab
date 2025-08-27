extends Node2D


var id_to_marker = {}
var marker_scale = 0.1


func create_invalid_marker(marker_position, id):
	var marker = Sprite2D.new()
	marker.set_texture(preload("res://Resources/Icons/LabTable/indicators/symbol_no.png"))
	marker.set_position(marker_position)
	marker.set_scale(Vector2.ONE * marker_scale)
	
	id_to_marker[id] = marker
	add_child(marker)


func remove_marker(id):
	if id_to_marker.has(id):
		id_to_marker[id].free()
		id_to_marker.erase(id)
