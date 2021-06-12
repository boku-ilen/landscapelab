extends LayerRenderer


var update_threads = []
var done = false

onready var lods = get_children()


func _ready():
	# Create a loading thread for each LOD child
	for lod in lods:
		lod.height_layer = layer.render_info.height_layer.clone()
		lod.texture_layer = layer.render_info.texture_layer.clone()


func load_new_data():
	for lod in lods:
		lod.position_x = center[0]
		lod.position_y = center[1]
		
		lod.build()


func apply_new_data():
	for lod in get_children():
		lod.apply_textures()
