extends MeshInstance


export var mesh_size: float


func apply_textures(heightmap, surface_heightmap, landuse):
	if not material_override:
		logger.warn("ExtraLOD with no Material Override! This will have no effect.")
		return
	
	material_override.set_shader_param("heightmap", heightmap)
	material_override.set_shader_param("surface_heightmap", surface_heightmap)
	material_override.set_shader_param("landuse", landuse)
	material_override.set_shader_param("size", get_parent().size)
	
	# Don't scale via Transform (this breaks shaders), but via the mesh size
	scale = get_parent().scale.inverse()
	mesh.size = Vector2(get_parent().size, get_parent().size)
