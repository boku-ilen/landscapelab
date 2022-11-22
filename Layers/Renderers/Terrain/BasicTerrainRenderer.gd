extends LayerCompositionRenderer


@onready var lods = get_children()


func _ready():
	super._ready()
	# Create a loading thread for each LOD child
	for lod in lods:
		lod.height_layer = layer_composition.render_info.height_layer.clone()
		lod.texture_layer = layer_composition.render_info.texture_layer.clone()
		
		lod.is_color_shaded = layer_composition.render_info.is_color_shaded
		if not layer_composition.render_info.is_color_shaded:
			# FIXME: I dont know why a duplicate is necessary but somehow it seems to be...
			lod.material_override = load("res://Layers/Renderers/Terrain/Materials/TerrainShader.tres").duplicate()
		else:
			# FIXME: I dont know why a duplicate is necessary but somehow it seems to be...
			lod.material_override = load("res://Layers/Renderers/Terrain/TerrainDataShader.tres").duplicate()
			lod.material_override.set_shader_parameter("min_value", layer_composition.render_info.min_value)
			lod.material_override.set_shader_parameter("max_value", layer_composition.render_info.max_value)
			lod.material_override.set_shader_parameter("min_color", layer_composition.render_info.min_color)
			lod.material_override.set_shader_parameter("max_color", layer_composition.render_info.max_color)
			lod.material_override.set_shader_parameter("alpha", layer_composition.render_info.alpha)


func full_load():
	for lod in lods:
		lod.position_x = center[0]
		lod.position_y = center[1]
		
		lod.build()


func apply_new_data():
	for lod in get_children():
		lod.apply_textures()
