extends LayerRenderer


onready var plane = get_node("TexturePlane")


func _ready():
	plane.texture_layer = layer.render_info.texture_layer.clone()


func load_new_data():
	plane.position_x = center[0]
	plane.position_y = center[1]
	plane.build()


func apply_new_data():
	plane.apply_textures()


func get_debug_info() -> String:
	return "2D map."
