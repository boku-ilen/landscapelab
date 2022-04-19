extends LayerRenderer


onready var lods = get_children()


func _ready():
	# Create a loading thread for each LOD child
	for lod in lods:
		lod.height_layer = layer.render_info.height_layer.clone()
		lod.texture_layer = layer.render_info.texture_layer.clone()
		
		lod.is_color_shaded = layer.render_info.is_color_shaded
		if not layer.render_info.is_color_shaded:
			# FIXME: I dont know why a duplicate is necessary but somehow it seems to be...
			lod.material_override = load("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres").duplicate()
		else:
			# FIXME: I dont know why a duplicate is necessary but somehow it seems to be...
			lod.material_override = load("res://Layers/Renderers/Terrain/TerrainDataShader.tres").duplicate()
			lod.material_override.set_shader_param("min_value", layer.render_info.min_value)
			lod.material_override.set_shader_param("max_value", layer.render_info.max_value)
			lod.material_override.set_shader_param("min_color", layer.render_info.min_color)
			lod.material_override.set_shader_param("max_color", layer.render_info.max_color)
			lod.material_override.set_shader_param("alpha", layer.render_info.alpha)


func load_new_data():
	for lod in lods:
		lod.position_x = center[0]
		lod.position_y = center[1]
		
		lod.build()


func apply_new_data():
	for lod in get_children():
		lod.apply_textures()
