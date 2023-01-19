extends LayerCompositionRenderer


@onready var plane = get_node("TexturePlane")


func _ready():
	super._ready()
	plane.texture_layer = layer_composition.render_info.texture_layer.clone()


func full_load():
	plane.position_x = center[0]
	plane.position_y = center[1]
	plane.build()


func apply_new_data():
	plane.apply_textures()


func get_debug_info() -> String:
	return "2D map."
