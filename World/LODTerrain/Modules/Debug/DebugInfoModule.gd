extends Module


onready var label = get_node("Viewport/MarginContainer/CenterContainer/Label")
onready var sprite_anchor = get_node("SpriteAnchor")


func init():
	_done_loading()


func _process(delta):
	label.text = "Distance: " + str(tile.get_dist_to_player()) + "\nLOD: " + str(tile.lod)
