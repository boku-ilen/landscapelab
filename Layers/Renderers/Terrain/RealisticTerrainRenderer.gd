extends LayerRenderer


onready var lods = get_children()


func _ready():
	# Create a loading thread for each LOD child
	for lod in lods:
		# Note that the layers would need to be cloned if each LOD were to load its data in parallel!
		lod.height_layer = layer.render_info.height_layer.clone()
		lod.texture_layer = layer.render_info.texture_layer.clone()
		lod.landuse_layer = layer.render_info.landuse_layer.clone()
		lod.surface_height_layer = layer.render_info.surface_height_layer.clone()


func load_new_data():
	for lod in lods:
		lod.position_x = center[0]
		lod.position_y = center[1]
		
		lod.build()


func apply_new_data():
	for lod in get_children():
		lod.apply_textures()


func get_debug_info() -> String:
	return "{0} LODs with a maximum size of {1} m.".format([
		lods.size(),
		lods.back().size
	])
